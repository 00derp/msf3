//===============================================================================================//
// Copyright (c) 2008 Stephen Fewer of Harmony Security
//===============================================================================================//
/*

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
	  this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.

    * Neither the name of Harmony Security nor the names of its contributors 
	  may be used to endorse or promote products derived from this software 
	  without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/
#ifndef REFLECTIVELOADER_H
#define REFLECTIVELOADER_H
//===============================================================================================//
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <Winsock2.h>
#include <Winternl.h>

#define EXITFUNC_SEH		0xEA320EFE
#define EXITFUNC_THREAD		0x0A2A1DE0
#define EXITFUNC_PROCESS	0x56A2B5F0

#define DLL_METASPLOIT_ATTACH	4
#define DLL_METASPLOIT_DETACH	5

#define DEREF_32( name )*(DWORD *)(name)
#define DEREF_16( name )*(WORD *)(name)
#define DEREF_8( name )*(BYTE *)(name)

#define DLLEXPORT   __declspec( dllexport ) 

typedef HMODULE (WINAPI * LOADLIBRARYA)( LPCSTR );
typedef FARPROC (WINAPI * GETPROCADDRESS)( HMODULE, LPCSTR );
typedef LPVOID  (WINAPI * VIRTUALALLOC)( LPVOID, SIZE_T, DWORD, DWORD );
typedef BOOL    (WINAPI * DLLMAIN)( HINSTANCE, DWORD, LPVOID );

#define KERNEL32DLL_HASH		0x6A4ABC5B
#define LOADLIBRARYA_HASH		0xEC0E4E8E
#define GETPROCADDRESS_HASH		0x7C0DFCAA
#define VIRTUALALLOC_HASH		0x91AFCA54

#define HASH_KEY	13	
//===============================================================================================//
__forceinline DWORD __hash( char * c )
{
    register DWORD h = 0;
	do
	{
		__asm ror h, HASH_KEY
        h += *c;
	} while( *++c );

    return h;
}
//===============================================================================================//
__forceinline DWORD __get_peb()
{
	__asm mov eax, fs:[ 0x30 ]
}
//===============================================================================================//
__forceinline VOID __memzero( DWORD dwDest, DWORD dwLength )
{
	__asm
	{
		mov ecx, dwLength
		xor eax, eax
		mov edi, dwDest
		rep stosb
	}
}
//===============================================================================================//
__forceinline VOID __memcpy( DWORD dwDest, DWORD dwSource, DWORD dwLength )
{
	__asm
	{
		mov ecx, dwLength
		mov esi, dwSource
		mov edi, dwDest
		rep movsb
	}
}
//===============================================================================================//

typedef struct _UNICODE_STR
{
  USHORT Length;
  USHORT MaximumLength;
  PWSTR pBuffer;
} UNICODE_STR, *PUNICODE_STR;

typedef struct _LDR_MODULE_MEMORY_ORDER
{
	LIST_ENTRY InMemoryOrderModuleList;
	LIST_ENTRY InInitializationOrderModuleList;
	PVOID BaseAddress;
	PVOID EntryPoint;
	ULONG SizeOfImage;
	UNICODE_STR FullDllName;
	UNICODE_STR BaseDllName;
	ULONG Flags;
	SHORT LoadCount;
	SHORT TlsIndex;
	LIST_ENTRY HashTableEntry;
	ULONG TimeDateStamp;
} LDR_MODULE_MEMORY_ORDER, *PLDR_MODULE_MEMORY_ORDER;

// WinDbg> dt -v ntdll!_PEB_LDR_DATA
typedef struct _PEB_LDR_DATA //, 7 elements, 0x28 bytes
{
   DWORD dwLength;
   DWORD dwInitialized;
   LPVOID lpSsHandle;
   LIST_ENTRY InLoadOrderModuleList;
   LIST_ENTRY InMemoryOrderModuleList;
   LIST_ENTRY InInitializationOrderModuleList;
   LPVOID lpEntryInProgress;
} PEB_LDR_DATA, * PPEB_LDR_DATA;

// WinDbg> dt -v ntdll!_PEB_FREE_BLOCK
typedef struct _PEB_FREE_BLOCK // 2 elements, 0x8 bytes
{
   struct _PEB_FREE_BLOCK * pNext;
   DWORD dwSize;
} PEB_FREE_BLOCK, * PPEB_FREE_BLOCK;

typedef struct _UNICODE_STRING {
    USHORT Length;
    USHORT MaximumLength;
    PWSTR  Buffer;
} UNICODE_STRING;
typedef UNICODE_STRING *PUNICODE_STRING;

// struct _PEB is defined in Winternl.h but it is incomplete
// WinDbg> dt -v ntdll!_PEB
typedef struct __PEB // 65 elements, 0x210 bytes
{
   BYTE bInheritedAddressSpace;
   BYTE bReadImageFileExecOptions;
   BYTE bBeingDebugged;
   BYTE bSpareBool;
   LPVOID lpMutant;
   LPVOID lpImageBaseAddress;
   PPEB_LDR_DATA pLdr;
   LPVOID lpProcessParameters;
   LPVOID lpSubSystemData;
   LPVOID lpProcessHeap;
   PRTL_CRITICAL_SECTION pFastPebLock;
   LPVOID lpFastPebLockRoutine;
   LPVOID lpFastPebUnlockRoutine;
   DWORD dwEnvironmentUpdateCount;
   LPVOID lpKernelCallbackTable;
   DWORD dwSystemReserved;
   DWORD dwAtlThunkSListPtr32;
   PPEB_FREE_BLOCK pFreeList;
   DWORD dwTlsExpansionCounter;
   LPVOID lpTlsBitmap;
   DWORD dwTlsBitmapBits[2];
   LPVOID lpReadOnlySharedMemoryBase;
   LPVOID lpReadOnlySharedMemoryHeap;
   LPVOID lpReadOnlyStaticServerData;
   LPVOID lpAnsiCodePageData;
   LPVOID lpOemCodePageData;
   LPVOID lpUnicodeCaseTableData;
   DWORD dwNumberOfProcessors;
   DWORD dwNtGlobalFlag;
   LARGE_INTEGER liCriticalSectionTimeout;
   DWORD dwHeapSegmentReserve;
   DWORD dwHeapSegmentCommit;
   DWORD dwHeapDeCommitTotalFreeThreshold;
   DWORD dwHeapDeCommitFreeBlockThreshold;
   DWORD dwNumberOfHeaps;
   DWORD dwMaximumNumberOfHeaps;
   LPVOID lpProcessHeaps;
   LPVOID lpGdiSharedHandleTable;
   LPVOID lpProcessStarterHelper;
   DWORD dwGdiDCAttributeList;
   LPVOID lpLoaderLock;
   DWORD dwOSMajorVersion;
   DWORD dwOSMinorVersion;
   WORD wOSBuildNumber;
   WORD wOSCSDVersion;
   DWORD dwOSPlatformId;
   DWORD dwImageSubsystem;
   DWORD dwImageSubsystemMajorVersion;
   DWORD dwImageSubsystemMinorVersion;
   DWORD dwImageProcessAffinityMask;
   DWORD dwGdiHandleBuffer[34];
   LPVOID lpPostProcessInitRoutine;
   LPVOID lpTlsExpansionBitmap;
   DWORD dwTlsExpansionBitmapBits[32];
   DWORD dwSessionId;
   ULARGE_INTEGER liAppCompatFlags;
   ULARGE_INTEGER liAppCompatFlagsUser;
   LPVOID lppShimData;
   LPVOID lpAppCompatInfo;
   UNICODE_STRING usCSDVersion;
   LPVOID lpActivationContextData;
   LPVOID lpProcessAssemblyStorageMap;
   LPVOID lpSystemDefaultActivationContextData;
   LPVOID lpSystemAssemblyStorageMap;
   DWORD dwMinimumStackCommit;
} _PEB, * _PPEB;

typedef struct
{
	WORD	offset:12;
	WORD	type:4;
} IMAGE_RELOC, *PIMAGE_RELOC;
//===============================================================================================//
#endif
//===============================================================================================//
