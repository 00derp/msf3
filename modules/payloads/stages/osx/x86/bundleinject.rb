##
# $Id: bundleinject.rb 6479 2009-04-13 14:33:26Z kris $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'
require 'msf/core/payload/osx/bundleinject'


###
#
# Injects an arbitrary DLL in the exploited process.
#
###
module Metasploit3

	include Msf::Payload::Osx::BundleInject

end
