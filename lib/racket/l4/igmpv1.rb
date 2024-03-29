# $Id: igmpv1.rb 14 2008-03-02 05:42:30Z warchild $
#
# Copyright (c) 2008, Jon Hart 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the <organization> nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY Jon Hart ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL Jon Hart BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Internet Group Management Protocol, Version 1
#
# RFC1112 (http://www.faqs.org/rfcs/rfc1112.html)
# 
module Racket
class IGMPv1 < RacketPart
  # Version (defaults to 1)
  unsigned :version, 4
  # Type
  unsigned :type, 4
  # Unused
  unsigned :unused, 8
  # Checksum
  unsigned :csum, 16
  # Group Address
  octets :gaddr, 32
  # Payload
  rest :payload

  # Check the checksum for this IGMP message
  def checksum?
    self.csum == 0 || (self.csum == compute_checksum)
  end
  
  # Compute and set the checkum for this IGMP message
  def checksum!
    self.csum = compute_checksum
  end

  # Do whatever 'fixing' is neccessary in preparation
  # for being sent
  def fix!
    self.checksum!
  end

private
  def compute_checksum
    # The checksum is the 16-bit one's complement of the one's complement sum
    # of the 8-octet IGMP message.  For computing the checksum, the checksum
    # field is zeroed.
    tmp = []
    tmp << ((((self.version << 4) | self.type) << 8) | self.unused)
    tmp << 0
    tmp << L3::Misc.ipv42long(self.gaddr)
    tmp << self.payload
    L3::Misc.checksum(tmp.pack("nnNa*"))
  end
end
end
# vim: set ts=2 et sw=2:
