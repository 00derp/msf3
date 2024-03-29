##
# $Id: pipe_auditor.rb 6479 2009-04-13 14:33:26Z kris $
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
	include Msf::Exploit::Remote::SMB
	
	# Scanner mixin should be near last
	include Msf::Auxiliary::Scanner
	
	def initialize
		super(
			'Name'        => 'SMB Session Pipe Auditor',
			'Version'     => '$Revision: 6479 $',
			'Description' => 'Determine what named pipes are accessible over SMB',
			'Author'      => 'hdm',
			'License'     => MSF_LICENSE
		)
		
		deregister_options('RPORT')
	end

	@@target_pipes = [
		'netlogon',
		'lsarpc',
		'samr',
		'browser',
		'atsvc',
		'DAV RPC SERVICE',
		'epmapper',
		'eventlog',
		'InitShutdown',
		'keysvc',
		'lsass',
		'LSM_API_service',
		'ntsvcs',
		'plugplay',
		'protected_storage',
		'router',
		'SapiServerPipeS-1-5-5-0-70123',
		'scerpc',
		'srvsvc',
		'tapsrv',
		'trkwks',
		'W32TIME_ALT',
		'wkssvc',
		'PIPE_EVENTROOT\CIMV2SCM EVENT PROVIDER'
	]
	
	# Fingerprint a single host
	def run_host(ip)

		pass = []
		
		[[139, false], [445, true]].each do |info|

		datastore['RPORT'] = info[0]
		datastore['SMBDirect'] = info[1]
		
		begin
			connect()
			smb_login()
			@@target_pipes.each do |pipe|
				begin
					fid = smb_create("\\#{pipe}")
					# print_status("Opened pipe \\#{pipe}")
					pass.push(pipe)
				rescue ::Rex::Proto::SMB::Exceptions::ErrorCode => e
					# print_error("Could not open \\#{pipe}: Error 0x%.8x" % e.error_code)
				end
			end
			
			disconnect()

			break
		rescue ::Exception => e
			# print_line($!.to_s)
			# print_line($!.backtrace.join("\n"))			
		end
		end

		if(pass.length > 0)
			print_status("#{ip} - Pipes: #{pass.map{|c| "\\#{c}"}.join(", ")}")
		end
	end
	

end
