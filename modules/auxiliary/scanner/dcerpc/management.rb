##
# $Id: management.rb 6479 2009-04-13 14:33:26Z kris $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'


class Metasploit3 < Msf::Auxiliary

	# Exploit mixins should be called first
	include Msf::Exploit::Remote::DCERPC
	
	# Scanner mixin should be near last
	include Msf::Auxiliary::Scanner
	
	def initialize
		super(
			'Name'        => 'Remote Management Interface Discovery',
			'Version'     => '$Revision: 6479 $',
			'Description' => %q{
				This module can be used to obtain information from the Remote 
				Management Interface DCERPC service.
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

			ids = dcerpc_mgmt_inq_if_ids(rport)
			return if not ids
			ids.each do |id|
				print_status("UUID #{id[0]} v#{id[1]}")
				
				stats = dcerpc_mgmt_inq_if_stats(rport)
				print_status("\t stats: " + stats.map{|i| "0x%.8x" % i}.join(", ")) if stats
				
				live  = dcerpc_mgmt_is_server_listening(rport)
				print_status("\t listening: %.8x" % live) if live

				dead  = dcerpc_mgmt_stop_server_listening(rport)
				print_status("\t killed: %.8x" % dead) if dead

				princ = dcerpc_mgmt_inq_princ_name(rport)
				print_status("\t name: #{princ.unpack("H*")[0]}") if princ
												
			end
			
		rescue ::Interrupt
			raise $!
		rescue ::Exception => e
			print_status("Error: #{e}")
		end
	end
	

end