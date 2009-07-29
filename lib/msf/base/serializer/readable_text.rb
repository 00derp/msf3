module Msf
module Serializer

###
#
# This class formats information in a plain-text format that
# is meant to be displayed on a console or some other non-GUI
# medium.
#
###
class ReadableText

	DefaultColumnWrap = 70
	DefaultIndent     = 2

	#
	# Returns a formatted string that contains information about
	# the supplied module instance.
	#
	def self.dump_module(mod, indent = "  ")
		case mod.type
			when MODULE_PAYLOAD
				return dump_payload_module(mod, indent)
			when MODULE_NOP
				return dump_basic_module(mod, indent)
			when MODULE_ENCODER
				return dump_basic_module(mod, indent)
			when MODULE_EXPLOIT
				return dump_exploit_module(mod, indent)
			when MODULE_AUX
				return dump_auxiliary_module(mod, indent)
			else
				return dump_generic_module(mod, indent)
		end
	end

	#
	# Dumps an exploit's targets.
	#
	def self.dump_exploit_targets(mod, indent = '', h = nil)
		tbl = Rex::Ui::Text::Table.new(
			'Indent'  => indent.length,
			'Header'  => h,
			'Columns' =>
				[
					'Id', 
					'Name',
				])

		mod.targets.each_with_index { |target, idx|
			tbl << [ idx.to_s, target.name || 'All' ]	
		}

		tbl.to_s + "\n"
	end

	#
	# Dumps the exploit's selected target
	#
	def self.dump_exploit_target(mod, indent = '', h = nil)
		tbl = Rex::Ui::Text::Table.new(
			'Indent'  => indent.length,
			'Header'  => h,
			'Columns' =>
				[
					'Id', 
					'Name',
				])

		tbl << [ mod.target_index, mod.target.name || 'All' ]

		tbl.to_s + "\n"
	end
	
	#
	# Dumps an auxiliary's actions
	#
	def self.dump_auxiliary_actions(mod, indent = '', h = nil)
		tbl = Rex::Ui::Text::Table.new(
			'Indent'  => indent.length,
			'Header'  => h,
			'Columns' =>
				[
					'Name',
					'Description'
				])

		mod.actions.each_with_index { |target, idx|
			tbl << [ target.name || 'All' , target.description || '' ]	
		}

		tbl.to_s + "\n"
	end
	
	#
	# Dumps the table of payloads that are compatible with the supplied
	# exploit.
	#
	def self.dump_compatible_payloads(exploit, indent = '', h = nil)
		tbl = Rex::Ui::Text::Table.new(
			'Indent'  => indent.length,
			'Header'  => h,
			'Columns' =>
				[
					'Name', 
					'Description',
				])

		exploit.compatible_payloads.each { |entry|
			tbl << [ entry[0], entry[1].new.description ]
		}

		tbl.to_s + "\n"
	end

	#
	# Dumps information about an exploit module.
	#
	def self.dump_exploit_module(mod, indent = '')
		output  = "\n"
		output << "       Name: #{mod.name}\n"
		output << "    Version: #{mod.version}\n"
		output << "   Platform: #{mod.platform_to_s}\n"
		output << " Privileged: " + (mod.privileged? ? "Yes" : "No") + "\n"
		output << "    License: #{mod.license}\n"
		output << "\n"

		# Authors
		output << "Provided by:\n"
		mod.each_author { |author|
			output << indent + author.to_s + "\n"
		}
		output << "\n"

		# Targets
		output << "Available targets:\n"
		output << dump_exploit_targets(mod, indent)
		
		# Options
		if (mod.options.has_options?)
			output << "Basic options:\n"
			output << dump_options(mod, indent)
			output << "\n"
		end
		
		# Payload information
		if (mod.payload_info.length)
			output << "Payload information:\n"
			if (mod.payload_space)
				output << indent + "Space: " + mod.payload_space.to_s + "\n"
			end
			if (mod.payload_badchars)
				output << indent + "Avoid: " + mod.payload_badchars.length.to_s + " characters\n"
			end
			output << "\n"
		end
	
		# Description
		output << "Description:\n"
		output << word_wrap(Rex::Text.compress(mod.description))
		output << "\n"

		# References
		if (mod.references.length > 0)
			output << "References:\n"
			mod.references.each { |ref|
				output << indent + ref.to_s + "\n"
			}
			output << "\n"
		end
	
		return output

	end

	#
	# Dumps information about an auxiliary module.
	#
	def self.dump_auxiliary_module(mod, indent = '')
		output  = "\n"
		output << "       Name: #{mod.name}\n"
		output << "    Version: #{mod.version}\n"
		output << "    License: #{mod.license}\n"
		output << "\n"

		# Authors
		output << "Provided by:\n"
		mod.each_author { |author|
			output << indent + author.to_s + "\n"
		}
		output << "\n"

		# Options
		if (mod.options.has_options?)
			output << "Basic options:\n"
			output << dump_options(mod, indent)
			output << "\n"
		end
		
		# Description
		output << "Description:\n"
		output << word_wrap(Rex::Text.compress(mod.description))
		output << "\n"

		# References
		if (mod.references.length > 0)
			output << "References:\n"
			mod.references.each { |ref|
				output << indent + ref.to_s + "\n"
			}
			output << "\n"
		end
	
		return output
	end

	# 
	# Dumps information about a payload module.
	#
	def self.dump_payload_module(mod, indent = '')
		# General
		output  = "\n"
		output << "       Name: #{mod.name}\n"
		output << "    Version: #{mod.version}\n"
		output << "   Platform: #{mod.platform_to_s}\n"
		output << "       Arch: #{mod.arch_to_s}\n"
		output << "Needs Admin: " + (mod.privileged? ? "Yes" : "No") + "\n"
		output << " Total size: #{mod.size}\n"
		output << "\n"

		# Authors
		output << "Provided by:\n"
		mod.each_author { |author|
			output << indent + author.to_s + "\n"
		}
		output << "\n"

		# Options
		if (mod.options.has_options?)
			output << "Basic options:\n"
			output << dump_options(mod)
			output << "\n"
		end

		# Description
		output << "Description:\n"
		output << word_wrap(Rex::Text.compress(mod.description))
		output << "\n\n"
	
		return output
	end

	#
	# Dumps information about a module, just the basics.
	#
	def self.dump_basic_module(mod, indent = '')
		# General
		output  = "\n"
		output << "       Name: #{mod.name}\n"
		output << "    Version: #{mod.version}\n"
		output << "   Platform: #{mod.platform_to_s}\n"
		output << "       Arch: #{mod.arch_to_s}\n"
		output << "\n"

		# Authors
		output << "Provided by:\n"
		mod.each_author { |author|
			output << indent + author.to_s + "\n"
		}
		output << "\n"
		
		# Description
		output << "Description:\n"
		output << word_wrap(Rex::Text.compress(mod.description))
		output << "\n\n"
	
		return output

	end

	def self.dump_generic_module(mod, indent = '')
	end

	#
	# Dumps the list of options associated with the
	# supplied module.
	#
	def self.dump_options(mod, indent = '')
		tbl = Rex::Ui::Text::Table.new(
			'Indent'  => indent.length,
			'Columns' =>
				[
					'Name', 
					'Current Setting',
					'Required',
					'Description'
				])

		mod.options.sorted.each { |entry|
			name, opt = entry

			next if (opt.advanced?)
			next if (opt.evasion?)
			
			val = mod.datastore[name] || opt.default.to_s

			tbl << [ name, val.to_s, opt.required? ? "yes" : "no", opt.desc ]
		}

		return tbl.to_s
	end

	#
	# Dumps the advanced options associated with the supplied module.
	#
	def self.dump_advanced_options(mod, indent = '')
		output = ''
		pad    = indent

		mod.options.sorted.each { |entry|
			name, opt = entry

			next if (!opt.advanced?)

			val = mod.datastore[name] || opt.default.to_s
			desc = word_wrap(opt.desc, indent.length + 3)
			desc = desc.slice(indent.length + 3, desc.length)

			output << pad + "Name           : #{name}\n"
			output << pad + "Current Setting: #{val}\n"
			output << pad + "Description    : #{desc}\n"
		}

		return output
	end

	#
	# Dumps the evasion options associated with the supplied module.
	#
	def self.dump_evasion_options(mod, indent = '')
		output = ''
		pad    = indent

		mod.options.sorted.each { |entry|
			name, opt = entry

			next if (!opt.evasion?)

			val = mod.datastore[name] || opt.default || ''
			
			desc = word_wrap(opt.desc, indent.length + 3)
			desc = desc.slice(indent.length + 3, desc.length)

			output << pad + "Name           : #{name}\n"
			output << pad + "Current Setting: #{val}\n"
			output << pad + "Description    : #{desc}\n"
		}

		return output
	end
	
	#
	# Dumps the contents of a datastore.
	#
	def self.dump_datastore(name, ds, indent = DefaultIndent, col = DefaultColumnWrap)
		tbl = Rex::Ui::Text::Table.new(
			'Indent'  => indent,
			'Header'  => name,
			'Columns' =>
				[
					'Name', 
					'Value'
				])

		ds.keys.sort.each { |k|
			tbl << [ k, (ds[k] != nil) ? ds[k].to_s : '' ]
		}

		return ds.length > 0 ? tbl.to_s : "#{tbl.header_to_s}No entries in data store.\n"
	end

	#
	# Dumps the list of active sessions.
	#
	def self.dump_sessions(framework, verbose = false, indent = DefaultIndent, col = DefaultColumnWrap)
		columns = 
			[
				'Id',
				'Description',
				'Tunnel'
			]

		columns << 'Via' if verbose

		tbl = Rex::Ui::Text::Table.new(
			'Indent'  => indent,
			'Header'  => "Active sessions",
			'Columns' => columns)

		framework.sessions.each_sorted { |k|
			session = framework.sessions[k]

			row = [ session.sid.to_s, session.desc, session.tunnel_to_s ]
			row << session.via_exploit if verbose and session.via_exploit

			tbl << row
		}

		return framework.sessions.length > 0 ? tbl.to_s : "#{tbl.header_to_s}No active sessions.\n"
	end

	#
	# Dumps the list of running jobs.
	#
	def self.dump_jobs(framework, indent = DefaultIndent, col = DefaultColumnWrap)
		tbl = Rex::Ui::Text::Table.new(
			'Indent'  => indent,
			'Header'  => "Jobs",
			'Columns' =>
				[
					'Id',
					'Name'
				])

		framework.jobs.keys.sort.each { |k|
			tbl << [ k, framework.jobs[k].name ]
		}

		return framework.jobs.keys.length > 0 ? tbl.to_s : "#{tbl.header_to_s}No active jobs.\n"
	end

	#
	# Jacked from Ernest Ellingson <erne [at] powernav.com>, modified
	# a bit to add indention
	#
	def self.word_wrap(str, indent = DefaultIndent, col = DefaultColumnWrap)
		return Rex::Text.wordwrap(str, indent, col)
	end

end

end end
