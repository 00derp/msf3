/////////////////////////////////////////////////////////////////////////////
// VNC Hooks library
//
// WinVNC uses this DLL to hook into the system message pipeline, allowing it
// to intercept messages which may be relevant to screen update strategy
//
//  Copyright (C) 2002-2003 RealVNC Ltd. All Rights Reserved.
//  Copyright (C) 1997 AT&T Laboratories Cambridge. All Rights Reserved.
//
//  This file is part of the VNC system.
//
//  The VNC system is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307,
//  USA.
//
// If the source code for the VNC system is not available from the place 
// whence you received this file, check http://www.uk.research.att.com/vnc or contact
// the authors on vnc@uk.research.att.com for information on obtaining it.

// VNC Hooks library
//
// This version created:
// 24/11/97

#if !defined(_VNCHOOKS_DLL_)
#define _VNCHOOKS_DLL_

#include <windows.h>

/////////////////////////////////////////////////////////////////////////////
// Define the import/export tags

#define DllImport __declspec(dllimport)
#define DllExport __declspec(dllexport)

/////////////////////////////////////////////////////////////////////////////
//
// Functions used by WinVNC

#define VNC_HOOKS_CATCHES_ALL 0x1					// Doesn't miss updates
#define VNC_HOOKS_CATCHES_MIN 0x2					// Reports minimal updates

extern "C"
{
	// DLL functions:
	DllExport DWORD HooksType();                    // Find out whether hooks are reliable/hints
	DllExport BOOL SetHooks(
		DWORD thread_id,
		UINT UpdateMsg,
		UINT CopyMsg,
		UINT MouseMsg
		);											// Set the hook
	DllExport BOOL UnSetHooks(DWORD thread_id);		// Remove it

	DllExport BOOL SetKeyboardFilterHook(BOOL activate);
													// Control keyboard filtering
	DllExport BOOL SetMouseFilterHook(BOOL activate);
													// Control mouse filtering
}

#endif // !defined(_VNCHOOKS_DLL_)
