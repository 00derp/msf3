##
# $Id: interact.rb 6847 2009-07-19 20:48:47Z egypt $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'
require 'msf/core/handler/find_tty'
require 'msf/base/sessions/command_shell'


module Metasploit3

	include Msf::Payload::Single

	def initialize(info = {})
		super(merge_info(info,
			'Name'          => 'Unix TTY, Interact with established connection',
			'Version'       => '$Revision: 6847 $',
			'Description'   => 'Interacts with a TTY on an established socket connection',
			'Author'        => 'hdm',
			'License'       => MSF_LICENSE,
			'Platform'      => 'unix',
			'Arch'          => ARCH_TTY,
			'Handler'       => Msf::Handler::FindTty,
			'Session'       => Msf::Sessions::TTY,
			'Payload'       =>
				{
					'Offsets' => { },
					'Payload' => ''
				}
			))
	end

end
