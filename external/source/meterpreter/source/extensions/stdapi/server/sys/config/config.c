#include "precomp.h"

/*
 * sys_getuid
 * ----------
 *
 * Gets the user information of the user the server is executing as
 */
DWORD request_sys_config_getuid(Remote *remote, Packet *packet)
{
	Packet *response = packet_create_response(packet);
	DWORD res = ERROR_SUCCESS;
	CHAR username[512], username_only[512], domainname_only[512];
	LPVOID TokenUserInfo[4096];
	HANDLE token;
	DWORD user_length = sizeof(username_only), domain_length = sizeof(domainname_only);
	DWORD size = sizeof(username), sid_type = 0, returned_tokinfo_length;

	memset(username, 0, sizeof(username));
	memset(username_only, 0, sizeof(username_only));
	memset(domainname_only, 0, sizeof(domainname_only));

	do
	{
		if (!OpenThreadToken(GetCurrentThread(), TOKEN_ALL_ACCESS, TRUE, &token))
			OpenProcessToken(GetCurrentProcess(), TOKEN_ALL_ACCESS, &token);

		if (!GetTokenInformation(token, TokenUser, TokenUserInfo, 4096, &returned_tokinfo_length))
		{
			res = GetLastError();
			break;
		}
		
		if (!LookupAccountSidA(NULL, ((TOKEN_USER*)TokenUserInfo)->User.Sid, username_only, &user_length, domainname_only, &domain_length, (PSID_NAME_USE)&sid_type))
		{
			res = GetLastError();
			break;
		}

 		// Make full name in DOMAIN\USERNAME format
		_snprintf(username, 512, "%s\\%s", domainname_only, username_only);
		username[511] = '\0';

		packet_add_tlv_string(response, TLV_TYPE_USER_NAME, username);

	} while (0);

	// Transmit the response
	packet_transmit_response(res, remote, response);

	return res;
}


/*
 * sys_sysinfo
 * ----------
 *
 * Get system information such as computer name and OS version
 */
DWORD request_sys_config_sysinfo(Remote *remote, Packet *packet)
{
	Packet *response = packet_create_response(packet);
	CHAR computer[512], buf[512], *osName = NULL, * osArch = NULL, * osWow = NULL;
	DWORD res = ERROR_SUCCESS;
	DWORD size = sizeof(computer);
	OSVERSIONINFOEX v;
	HMODULE hKernel32;

	memset(&v, 0, sizeof(v));
	memset(computer, 0, sizeof(computer));
	memset(buf, 0, sizeof(buf));

	v.dwOSVersionInfoSize = sizeof(OSVERSIONINFOEX);

	do
	{
		// Get the computer name
		if (!GetComputerName(computer, &size))
		{
			res = GetLastError();
			break;
		}

		packet_add_tlv_string(response, TLV_TYPE_COMPUTER_NAME, computer);

		// Get the operating system version information
		if (!GetVersionEx((LPOSVERSIONINFO)&v))
		{
			res = GetLastError();
			break;
		}

		if (v.dwMajorVersion == 3)
			osName = "Windows NT 3.51";
		else if (v.dwMajorVersion == 4)
		{
			if (v.dwMinorVersion == 0 && v.dwPlatformId == VER_PLATFORM_WIN32_WINDOWS)
				osName = "Windows 95";
			else if (v.dwMinorVersion == 10)
				osName = "Windows 98";
			else if (v.dwMinorVersion == 90)
				osName = "Windows ME";
			else if (v.dwMinorVersion == 0 && v.dwPlatformId == VER_PLATFORM_WIN32_NT)
				osName = "Windows NT 4.0";
		}
		else if (v.dwMajorVersion == 5)
		{
			if (v.dwMinorVersion == 0)
				osName = "Windows 2000";
			else if (v.dwMinorVersion == 1)
				osName = "Windows XP";
			else if (v.dwMinorVersion == 2)
				osName = "Windows .NET Server";
		}
		else if (v.dwMajorVersion == 6 && v.dwMinorVersion == 0)
		{
			if (v.wProductType == VER_NT_WORKSTATION)
				osName = "Windows Vista";
			else 
				osName = "Windows 2008";
		}
		else if (v.dwMajorVersion == 6 && v.dwMinorVersion == 1)
		{
			if (v.wProductType == VER_NT_WORKSTATION)
				osName = "Windows 7";
			else 
				osName = "Windows 2008 R2";
		}
		
		if (!osName)
			osName = "Unknown";
		
		_snprintf(buf, sizeof(buf) - 1, "%s (Build %lu, %s).", osName, 
				v.dwBuildNumber, v.szCSDVersion, osArch, osWow );

		packet_add_tlv_string(response, TLV_TYPE_OS_NAME, buf);

		// sf: we dynamically retrieve GetNativeSystemInfo & IsWow64Process as NT and 2000 dont support it.
		hKernel32 = LoadLibraryA( "kernel32.dll" );
		if( hKernel32 )
		{
			typedef void (WINAPI * GETNATIVESYSTEMINFO)( LPSYSTEM_INFO lpSystemInfo );
			typedef BOOL (WINAPI * ISWOW64PROCESS)( HANDLE, PBOOL );
			GETNATIVESYSTEMINFO pGetNativeSystemInfo = (GETNATIVESYSTEMINFO)GetProcAddress( hKernel32, "GetNativeSystemInfo" );
			ISWOW64PROCESS pIsWow64Process = (ISWOW64PROCESS)GetProcAddress( hKernel32, "IsWow64Process" );
			if( pGetNativeSystemInfo )
			{
				SYSTEM_INFO SystemInfo;
				pGetNativeSystemInfo( &SystemInfo );
				switch( SystemInfo.wProcessorArchitecture )
				{
					case PROCESSOR_ARCHITECTURE_AMD64:
						osArch = "x64";
						break;
					case PROCESSOR_ARCHITECTURE_IA64:
						osArch = "IA64";
						break;
					case PROCESSOR_ARCHITECTURE_INTEL:
						osArch = "x86";
						break;
					default:
						break;
				}
			}
			if( pIsWow64Process )
			{
				BOOL bIsWow64 = FALSE;
				pIsWow64Process( GetCurrentProcess(), &bIsWow64 );
				if( bIsWow64 )
					osWow = " (Current Process is WOW64)";
			}
		}
		// if we havnt set the arch it is probably because we are on NT/2000 which is x86
		if( !osArch )
			osArch = "x86";

		if( !osWow )
			osWow = "";

		_snprintf( buf, sizeof(buf) - 1, "%s%s", osArch, osWow );
		packet_add_tlv_string(response, TLV_TYPE_ARCHITECTURE, buf);

		if( hKernel32 )
		{
			char * ctryname = NULL, * langname = NULL;
			typedef LANGID (WINAPI * GETSYSTEMDEFAULTLANGID)( VOID );
			GETSYSTEMDEFAULTLANGID pGetSystemDefaultLangID = (GETSYSTEMDEFAULTLANGID)GetProcAddress( hKernel32, "GetSystemDefaultLangID" );
			if( pGetSystemDefaultLangID )
			{
				LANGID langId = pGetSystemDefaultLangID();

				int len = GetLocaleInfo( langId, LOCALE_SISO3166CTRYNAME, 0, 0 );
				if( len > 0 )
				{
					ctryname = (char *)malloc( len );
					GetLocaleInfo( langId, LOCALE_SISO3166CTRYNAME, ctryname, len ); 
				}
				
				len = GetLocaleInfo( langId, LOCALE_SISO639LANGNAME, 0, 0 );
				if( len > 0 )
				{
					langname = (char *)malloc( len );
					GetLocaleInfo( langId, LOCALE_SISO639LANGNAME, langname, len ); 
				}
			}

			if( !ctryname || !langname )
				_snprintf( buf, sizeof(buf) - 1, "Unknown");
			else
				_snprintf( buf, sizeof(buf) - 1, "%s_%s", langname, ctryname );
				
			packet_add_tlv_string( response, TLV_TYPE_LANG_SYSTEM, buf );

			if( ctryname )
				free( ctryname );

			if( langname )
				free( langname );
		}

			
	} while (0);

	// Transmit the response
	packet_transmit_response(res, remote, response);

	return res;
}


/*
 * sys_config_rev2self
 *
 * Calls RevertToSelf()
 */
DWORD request_sys_config_rev2self(Remote *remote, Packet *packet)
{
	RevertToSelf();

	packet_transmit_empty_response(remote, packet, GetLastError());

	return ERROR_SUCCESS;
}
