##
# $Id: endpoint_mapper.rb 6022 2008-12-19 07:11:08Z kris $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/projects/Framework/
##


require 'msf/core'


class Metasploit3 < Msf::Auxiliary

	# Exploit mixins should be called first
	include Msf::Exploit::Remote::DCERPC
	
	# Scanner mixin should be near last
	include Msf::Auxiliary::Scanner
	
	def initialize
		super(
			'Name'        => 'Endpoint Mapper Service Discovery',
			'Version'     => '$Revision: 6022 $',
			'Description' => %q{
				This module can be used to obtain information from the 
				Endpoint Mapper service.
			},
			'Author'      => 'hdm',
			'License'     => MSF_LICENSE
		)
		
		deregister_options('RHOST')
		
		register_options(
			[
				Opt::RPORT(135)
			], self.class)		
	end

	# Obtain information about a single host
	def run_host(ip)	
		begin

			ids = dcerpc_endpoint_list()
			return if not ids
			ids.each do |id|
				next if not id[:prot]
				line = "#{id[:uuid]} v#{id[:vers]} "
				line << "#{id[:prot].upcase} "
				line << "(#{id[:port]}) " if id[:port]
				line << "(#{id[:pipe]}) " if id[:pipe]
				line << "#{id[:host]} " if id[:host]
				line << "[#{id[:note]}]" if id[:note]
				print_status(line)							
			end
			
		rescue ::Interrupt
			raise $!
		rescue ::Exception => e
			print_status("Error: #{e}")
		end
	end
	

end