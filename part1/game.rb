
class Game
	def initialize
		@winner = nil
		@rules = []
	end

	attr_accessor :winner

	def on(trigger, body)
		@rules << { :trigger => trigger, :body => body }
	end

	def next
		@rules.each do |rule|
			if rule[:trigger].call then
				return rule[:body].call
			end
		end
	end

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
