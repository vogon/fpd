load './utility.rb'
load './game.rb'

class NumberGuess < Game
	def initialize(guesser, guessee)
		super()

		@goal = nil
		@guesses = []

		@guesser = PlayerProxy.new(self, guesser)
		@guessee = PlayerProxy.new(self, guessee)

		@on_guess = Event.new
		@on_game_over = Event.new

		on -> {guesses.index(goal)},
			(lambda do
				self.guesser.wins
				self.on_game_over.invoke(@winner)
				return true
			end)

		on -> { guesses.length == 3 },
			(lambda do
				self.guessee.wins
				self.on_game_over.invoke(@winner)
				true
			end)

		on -> { !goal },
			(lambda do
				self.goal = guessee.ask_number.demand
				nil
			end)

		on -> { true },
			(lambda do
				if guesses.length > 0 then
					if (goal > guesses.last) then
						self.on_guess.invoke(:higher)
					else
						self.on_guess.invoke(:lower)
					end
				end

				self.guesses << guesser.ask_guess.demand
				false
			end)
	end

	attr_accessor :on_guess
	attr_accessor :on_game_over

	attr_accessor :goal
	attr_accessor :guesses

	attr_reader :guesser, :guessee

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