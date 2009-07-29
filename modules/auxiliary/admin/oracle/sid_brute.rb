##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/projects/Framework/
##

require 'msf/core'

class Metasploit3 < Msf::Auxiliary

	include Msf::Auxiliary::Report
	include Msf::Exploit::Remote::TNS

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'ORACLE SID Brute Forcer.',
			'Description'    => %q{
				This module simply attempts to discover the protected SID.
			},
			'Author'         => [ 'MC' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision$',
                        'References'     =>
				[
					[ 'URL', 'https://www.metasploit.com/users/mc' ],
					[ 'URL' , 'http://www.red-database-security.com/scripts/sid.txt' ],
				],
			'DisclosureDate' => 'Jan 7 2009'))

                        register_options( 
                                [
                                        Opt::RPORT(1521),
					OptString.new('SLEEP', [ false,   'Sleep() amount between each request.', '1']),
					OptString.new('SIDFILE', [ false, 'The file that contains a list of sids.', File.join(Msf::Config.install_root, 'data', 'wordlists', 'sid.txt')]),
                                ], self.class)

	end

	def run

		s    = datastore['SLEEP']
		list = datastore['SIDFILE']

		print_status("Starting brute force on #{rhost}, using sids from #{list}...")
		
		fd = File.open(list).each do |sid|
	
		login = "(DESCRIPTION=(CONNECT_DATA=(SID=#{sid})(CID=(PROGRAM=)(HOST=MSF)(USER=)))(ADDRESS=(PROTOCOL=tcp)(HOST=#{rhost})(PORT=#{rport})))"

		pkt = tns_packet(login)

		begin
			connect
		rescue => e
			print_error("#{e}")
			disconnect
			return
		end

		sock.put(pkt)

		sleep(s.to_i)

		res = sock.get_once(-1,3)

		disconnect

		 	if ( res and res =~ /ERROR_STACK/ )
				''
			else
				report_note(:host => rhost, :proto => 'TNS', :port => rport, :type => 'BRUTEFORCED_SID', :data => "#{sid.strip}")
				print_status("Found SID '#{sid.strip!}' for host #{rhost}.")
			end
		end

		print_status("Done with brute force...")
		fd.close

	end
end
