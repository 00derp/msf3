##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Auxiliary

	include Msf::Auxiliary::Report
	include Msf::Auxiliary::Scanner
	include Msf::Exploit::Remote::Udp

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Motorola Timbuktu Service Detection.',
			'Description'    => %q{
				This module simply sends a packet to the Motorola Timbuktu service for detection.
			},
			'Author'         => ['MC'],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 7128 $',
			'DisclosureDate' => 'Sep 25 2009'))

                        register_options([Opt::RPORT(407),], self.class) 

			deregister_options('RHOST')
	end

	def run_host(ip)
		begin
			connect_udp

			ping = "\x00\x25\x00\x22\xFF\x01\x00\x64\x03\x07\x00\x05\x00\x01\x00\x00"

			udp_sock.write(ping)
			
			res = udp_sock.read(256)
				
				if ( res =~ /\x00\x25\xD0\xB9/ )
					report_note(
						:host	=> ip,
						:proto	=> 'udp',
						:port	=> datastore['RPORT'],
						:type	=> 'SERVICE',
						:data	=> 'Motorola Timbuktu Service Detection'
					)
					print_status("Motorola Timbuktu Detected on host #{ip}.")
				else
					print_error("Unable to determine info for #{ip}...")
				end
			disconnect_udp
		rescue ::Errno::EPIPE, ::Rex::HostUnreachable, ::Rex::ConnectionTimeout, ::Rex::ConnectionRefused 
		end
	end
end
