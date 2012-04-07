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

class Game
	def initialize
		@winner = nil
	end

	attr_accessor :winner

	private
	class PlayerProxy
		def initialize(game, player)
			@game = game
			@player = player
		end

		def wins
			@game.winner = @player
		end

		def method_missing(name, *args)
			@player.send(name, *args)
		end
	end
end

class NumberGuess < Game
	def initialize(guesser, guessee)
		@goal = nil
		@guesses = []

		@guesser = PlayerProxy.new(self, guesser)
		@guessee = PlayerProxy.new(self, guessee)

		@on_guess = Event.new
		@on_game_over = Event.new
	end

	attr_accessor :on_guess
	attr_accessor :on_game_over

	attr_accessor :goal
	attr_accessor :guesses

	attr_reader :guesser, :guessee

	def next
		if guesses.index(goal) then
			self.guesser.wins
			self.on_game_over.invoke(@winner)
			return true
		elsif guesses.length == 3 then
			self.guessee.wins
			self.on_game_over.invoke(@winner)
			return true
		elsif !(goal) then
			self.goal = guessee.ask_number.demand
			return nil
		else
			if guesses.length > 0 then
				if (goal > guesses.last) then
					self.on_guess.invoke(:higher)
				else
					self.on_guess.invoke(:lower)
				end
			end

			self.guesses << guesser.ask_guess.demand
			return false
		end
	end
end

class CPUPlayer
	def ask_number
		p = Future.new
		p.yield(Random.rand(1..10))

		return p
	end

	def ask_guess
		p = Future.new
		p.yield(Random.rand(1..10))

		return p
	end
end

class HumanPlayer
	def ask_number
		p = Future.new

		Thread.new do
			puts "what's your number?"
			p.yield(STDIN.readline.to_i)
		end

		return p
	end

	def ask_guess
		p = Future.new

		Thread.new do
			puts "what's your guess?"
			p.yield(STDIN.readline.to_i)
		end

		return p
	end
end

class Observer
	def initialize(game)
		game.on_guess += method(:tell_guess)
		game.on_game_over += method(:tell_game_over)
	end

	def tell_guess(dir)
		if (dir == :higher) then
			puts "guess higher"
		elsif (dir == :lower) then
			puts "guess lower"
		end
	end

	def tell_game_over(winner)
		puts "#{winner} wins!"
	end
end

game = NumberGuess.new(HumanPlayer.new, CPUPlayer.new)
o = Observer.new(game)

while !(game.next) do
end

game = NumberGuess.new(CPUPlayer.new, HumanPlayer.new)
o = Observer.new(game)

while !(game.next) do
end