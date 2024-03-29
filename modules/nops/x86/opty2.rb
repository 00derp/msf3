##
# $Id: opty2.rb 6479 2009-04-13 14:33:26Z kris $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'
require 'rex/nop/opty2'


###
#
# Opty2
# -----
#
# This class implements single-byte NOP generation for X86.  It takes from
# ADMmutate and from spoonfu.
#
###
class Metasploit3 < Msf::Nop

	def initialize
		super(
			'Name'        => 'Opty2',
			'Version'     => '$Revision: 6479 $',
			'Description' => 'Opty2 multi-byte NOP generator',
			'Author'      => [ 'spoonm', 'optyx' ],
			'License'     => MSF_LICENSE,
			'Arch'        => ARCH_X86)
	end

	def generate_sled(length, opts = {})
		opty = Rex::Nop::Opty2.new(
			opts['BadChars'] || '',
			opts['SaveRegisters'])

		opty.generate_sled(length)
	end

end