##
# $Id: wmap_backup_file.rb 6479 2009-04-13 14:33:26Z kris $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'rex/proto/http'
require 'msf/core'



class Metasploit3 < Msf::Auxiliary

	include Msf::Exploit::Remote::HttpClient
	include Msf::Auxiliary::WMAPScanFile
	include Msf::Auxiliary::Scanner

	def initialize(info = {})
		super(update_info(info,	
			'Name'   		=> 'HTTP Backup File Scanner',
			'Description'	=> %q{
				This module identifies the existence of possible copies 
				of a specific file in a given path.
			},
			'Author' 		=> [ 'et [at] cyberspace.org' ],
			'License'		=> BSD_LICENSE,
			'Version'		=> '$Revision: 6479 $'))   
			
		register_options(
			[
				OptString.new('PATH', [ true,  "The path/file to identify backups", '/index.asp'])
			], self.class)	
							
	end

	def run_host(ip)
		bakextensions = [
			'.backup',
			'.bak',
			'.copy',
			'.old', 
			'.orig',
			'.temp',
			'.txt',
			'~'
		]

		bakextensions.each do |ext|
			file = datastore['PATH']+ext
			check_for_file(file)
		end
		if datastore['PATH'] =~ %r#(.*)(/.+$)#
			file = $1 + $2.sub('/', '/.') + '.swp'
			check_for_file(file)
		end
	end
	def check_for_file(file)
		begin
			res = send_request_cgi({
					'uri'  		=>  file,
					'method'   	=> 'GET',
					'ctype'		=> 'text/plain'
					}, 20)

			if (res and res.code >= 200 and res.code < 300) 
				 	print_status("Found #{wmap_base_url}#{file}")
					
					rep_id = wmap_base_report_id(
						wmap_target_host,
						wmap_target_port,
						wmap_target_ssl
					)
					wmap_report(rep_id,'VULNERABILITY','BACKUP_FILE',"#{file}","A backup file was found.")
				else
				   	print_status("NOT Found http:#{wmap_base_url}#{file}") 
					#To be removed or just displayed with verbose debugging.
				end

		rescue ::Rex::ConnectionRefused, ::Rex::HostUnreachable, ::Rex::ConnectionTimeout
		rescue ::Timeout::Error, ::Errno::EPIPE			
		end
	
	
	end

end
