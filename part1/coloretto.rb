load './utility.rb'
load './game.rb'

Colors = [:green, :yellow, :pink, :gray, :brown, :blue,
		  :orange]
Scorable = Colors + [:plus2, :joker]
Cards = Scorable + [:lastround]

module StandardRules
	def build_deck(n)
		deck = []
		start_cards = []

		# if n < 4, drop some colors from the game
		local_colors = Colors.clone.shuffle
		if n == 3 then local_colors.pop(1) end
		if n == 2 then local_colors.pop(2) end

		# hand starting cards out to each player and toss the other colors into the deck
		if (n == 2) then
			n.times do |i|
				start_cards[i] = [local_colors[2*i], local_colors[2*i + 1]]
			end

			deck += local_colors.slice(2*n..-1)
		else
			n.times do |i|
				start_cards[i] = [local_colors[i]]
			end

			deck += local_colors.slice(n..-1)
		end

		# fill the rest of the deck up
		deck += local_colors * 8 + [:joker] * 3 + [:plus2] * 10

		# give it a good shuffle
		deck.shuffle!

		# stick in the last-round card
		deck = deck.slice(0...-15) + [:lastround] + deck.slice(-15..-1)

		{:start_cards => start_cards, :deck => deck}
	end

	def row_limits(n)
		if n == 2 then
			[1, 2, 3]
		else
			[3] * n
		end
	end
end

module NormalColorValues
	def value(n)
		case n
		when 0 then 0
		when 1 then 1
		when 2 then 3
		when 3 then 6
		when 4 then 10
		when 5 then 15
		else 21		
		end
	end
end

module AltColorValues
	def value(n)
		case n
		when 0 then 0
		when 1 then 1
		when 2 then 4
		when 3 then 8
		when 4 then 7
		when 5 then 6
		else 5
		end
	end
end

class ColorettoPlayer
	def initialize(game, fpd_player, start_cards)
		@game = game
		@fpd_player = fpd_player
		@scored = start_cards
	end

	attr_reader :game
	attr_reader :fpd_player

	def give_cards(cards)
		@scored += cards
	end

	def score
		counts = {}
		max_joker = nil
		max_joker_score = 0

		# bin each scored card by card type
		Scorable.each do |type|
			counts[type] = @scored.count(type)
		end

		# generate all possible joker assignments, compute
		# the one with maximal score
		Colors.repeated_combination(counts[:joker]).each do |asgt|
			# add assigned jokers to counts
			counts_joker = counts.clone

			asgt.each do |color|
				counts_joker[color] += 1
			end

			# compute score
			score = 0

			Colors.each do |color|
				score += @game.value(counts_joker[color])
			end

			score += 2 * counts_joker[:plus2]

			# and compare
			if (score > max_joker_score) then
				max_joker = counts_joker
				max_joker_score = score
			end
		end

		return max_joker_score
	end

end

class Coloretto < Game
	def initialize(players, color_values)
		super()
		self.extend(color_values)

		@players = []
		start_deck = build_deck(players.length)
		@deck = start_deck[:deck]

		players.length.times do |i|
			@players[i] = ColorettoPlayer.new(self, players[i], start_deck[:start_cards][i])
		end

		on -> { !round },
			(lambda do

			end)
	end

	attr_accessor :players

	include StandardRules
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
