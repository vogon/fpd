require 'thread'

# I messed around with converting this over to lazy.rb but I don't like the
# API; explicitly yielding a number and being able to yield it from outside
# a particular block produce nicer code, I think
class Future
	def initialize
		@mutex = Mutex.new
		@cv = ConditionVariable.new

		@yielded = false
		@value = nil
	end

	def demand
		while !(@yielded) do
			@mutex.synchronize {
				@cv.wait(@mutex)
			}
		end

		if (@yielded)
			return @value
		end
	end

	def yield(x)
		@mutex.synchronize {
			@yielded = true
			@value = x

			@cv.broadcast
		}
	end
end

class Event
	def initialize(cbs = [])
		@callbacks = cbs
	end

	def +(proc)
		Event.new(@callbacks + [proc])
	end

	def -(proc)
		Event.new(@callbacks - [proc])
	end

	def invoke(*args)
		@callbacks.each do |cb|
			cb.call(*args)
		end
		nil
	end
end
