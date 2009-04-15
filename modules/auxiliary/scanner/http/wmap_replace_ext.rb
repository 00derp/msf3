##
# $Id: wmap_replace_ext.rb 6479 2009-04-13 14:33:26Z kris $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'rex/proto/http'
require 'msf/core'
require 'pathname'



class Metasploit3 < Msf::Auxiliary

	include Msf::Exploit::Remote::HttpClient
	include Msf::Auxiliary::WMAPScanFile
	include Msf::Auxiliary::Scanner

	def initialize(info = {})
		super(update_info(info,	
			'Name'   		=> 'HTTP File Extension Scanner',
			'Description'	=> %q{
				This module identifies the existence of additional files 
				by modifying the extension of an existing file.
					
			},
			'Author' 		=> [ 'et [at] cyberspace.org' ],
			'License'		=> BSD_LICENSE,
			'Version'		=> '$Revision: 6479 $'))   
			
		register_options(
			[
				OptString.new('PATH', [ true,  "The path/file to identify additional files", '/default.asp']),
				OptString.new('EXT', [ false, "File extension to replace (blank for automatic replacement of extension)", '']), 
			], self.class)	
						
	end

	def run_host(ip)
 		
		extensions= [
			'bak',
 			'txt',
 			'tmp',
 			'old',
 			'temp',
 			'java',
 			'doc',
 			'log'
		]

		tpathfile = Pathname.new(datastore['PATH'])
		tpathnoext = tpathfile.to_s[0..datastore['PATH'].rindex(tpathfile.extname)]
  		

		extensions.each { |testext|
			begin
				tpath = tpathnoext+testext
					res = send_request_cgi({
						'uri'  		=>  tpath,
						'method'   	=> 'GET',
						'ctype'		=> 'text/plain'
				}, 20)

				if (res and res.code >= 200 and res.code < 300) 
					print_status("Found #{wmap_base_url}#{tpath}")
				   
					rep_id = wmap_base_report_id(
						wmap_target_host,
						wmap_target_port,
						wmap_target_ssl
					)
								
					vul_id = wmap_report(rep_id,'FILE','NAME',"#{tpath}","File #{tpath} found.")
					wmap_report(vul_id,'FILE','RESP_CODE',"#{res.code}",nil)
				else
					print_status("NOT Found #{wmap_base_url}#{tpath}") 
					#blah
				end

			rescue ::Rex::ConnectionRefused, ::Rex::HostUnreachable, ::Rex::ConnectionTimeout
			rescue ::Timeout::Error, ::Errno::EPIPE			
			end	
		}
	
	end

end
