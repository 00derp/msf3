#!/usr/bin/env ruby

require 'timeout'
require 'thread' 

module Rex
module Post
module Meterpreter

###
#
# This class handles waiting for a response to a given request
# and the subsequent response association.
#
###
class PacketResponseWaiter

	#
	# Initializes a response waiter instance for the supplied request
	# identifier.
	#
	def initialize(rid, completion_routine = nil, completion_param = nil)
		self.rid      = rid.dup
		self.response = nil

		if (completion_routine)
			self.completion_routine = completion_routine
			self.completion_param   = completion_param
		else
			self.mutex = Mutex.new
			self.cond  = ConditionVariable.new
		end
	end

	#
	# Checks to see if this waiter instance is waiting for the supplied 
	# packet based on its request identifier.
	#
	def waiting_for?(packet)
		return (packet.rid == rid)
	end

	#
	# Notifies the waiter that the supplied response packet has arrived.
	#
	def notify(response)
		self.response = response

		if (self.completion_routine)
			self.completion_routine(self.completion_param, response)
		else
			self.mutex.synchronize {
				self.cond.signal
			}
		end
	end

	#
	# Waits for a given time interval for the response packet to arrive.
	#
	def wait(interval)
		begin
			timeout(interval) { 
				self.mutex.synchronize { 
					self.cond.wait(self.mutex) 
				} 
			}
		rescue Timeout::Error
			self.response = nil
		end

		return self.response
	end

	attr_accessor :rid, :mutex, :cond, :response # :nodoc:
	attr_accessor :completion_routine, :completion_param # :nodoc:
end

end; end; end