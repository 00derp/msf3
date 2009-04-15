##
# $Id: scanner_host.rb 6479 2009-04-13 14:33:26Z kris $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'


class Metasploit3 < Msf::Auxiliary

	include Msf::Auxiliary::Scanner
	
	def initialize
		super(
			'Name'        => 'Simple Recon Module Tester',
			'Version'     => '$Revision: 6479 $',
			'Description' => 'Simple Recon Module Tester',
			'Author'      => 'hdm',
			'License'     => MSF_LICENSE
		)

		register_options(
			[
				Opt::RPORT,
			], self.class)	

	end

	def run_host(ip)
		print_status("Working on host #{ip}")
	end

	
end