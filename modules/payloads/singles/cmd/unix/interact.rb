##
# $Id: interact.rb 6479 2009-04-13 14:33:26Z kris $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'
require 'msf/core/handler/find_shell'
require 'msf/base/sessions/command_shell'


module Metasploit3

	include Msf::Payload::Single

	def initialize(info = {})
		super(merge_info(info,
			'Name'          => 'Unix Command, Interact with established connection',
			'Version'       => '$Revision: 6479 $',
			'Description'   => 'Interacts with a shell on an established socket connection',
			'Author'        => 'hdm',
			'License'       => MSF_LICENSE,
			'Platform'      => 'unix',
			'Arch'          => ARCH_CMD,
			'Handler'       => Msf::Handler::FindShell,
			'Session'       => Msf::Sessions::CommandShell,
			'PayloadType'   => 'cmd_interact',
			'Payload'       =>
				{
					'Offsets' => { },
					'Payload' => ''
				}
			))
	end

end
