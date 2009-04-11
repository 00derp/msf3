##
# $Id: mssql_ping.rb 5880 2008-11-11 05:12:52Z hdm $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/projects/Framework/
##


require 'msf/core'


class Metasploit3 < Msf::Auxiliary
        
	include Msf::Exploit::Remote::MSSQL
	include Msf::Auxiliary::Scanner
	
	def initialize
		super(
			'Name'           => 'MSSQL Ping Utility',
			'Version'        => '$Revision: 5880 $',
			'Description'    => 'This module simply queries the MSSQL instance for information.',
			'Author'         => 'MC',
			'License'        => MSF_LICENSE
		)
		
		deregister_options('RPORT', 'RHOST')
	end


	def run_host(ip)
		
		begin
		
		info = mssql_ping(2)
		if (info['ServerName'])
			print_status("SQL Server information for #{ip}:")
			info.each_pair { |k,v|
				print_status("   #{k + (" " * (15-k.length))} = #{v}")
			}
		end
		
		rescue ::Rex::ConnectionError
		end
	end
end
