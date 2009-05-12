##
# $Id: ssh_version.rb 6541 2009-05-11 02:46:59Z patrickw $
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
	include Msf::Auxiliary::Scanner
	include Msf::Auxiliary::Report
	
	def initialize
		super(
			'Name'        => 'SSH Version Scannner',
			'Version'     => '$Revision: 6541 $',
			'Description' => 'Detect SSH Version.',
			'References'  =>
				[
					[ 'URL', 'http://en.wikipedia.org/wiki/SecureShell' ],
				],
			'Author'      => [ 'Daniel van Eeden <metasploit@myname.nl>' ],
			'License'     => MSF_LICENSE
		)

		register_options(
		[
			Opt::RPORT(22),
		], self.class)
	end

	def run_host(target_host)
		
		connect

		ver = sock.get_once(50,1)
		ver,msg = (ver.split(/(\n|\r)/))

		if (ver =~ /SSH/)
			print_status("#{target_host}:#{rport}, SSH server version: #{ver}")
			report_service(:host => rhost, :port => rport, :name => "ssh")
		else
			print_status("#{target_host}:#{rport}, SSH server version detection failed!")
		end

		disconnect
	end
end
