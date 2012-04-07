def play
	puts "let's play a game.  the game is called 'guess the number.'"

	goal = Random.rand(1..10)

	puts "I chose a number between 1 and 10. can you guess it?"

	3.times do |n|
		puts "guess #{n + 1}: "
		guess = STDIN.readline.to_i

		if guess === (1..10) or !(guess.is_a? Fixnum) then
			puts "that's not a valid guess!"
		else
			if goal == guess then
				puts "good job!  my number was #{goal}!"
				return true
			elsif goal > guess then
				puts "it's a little higher than that."
			else
				puts "it's a little lower than that."
			end
		end
	end

	puts "sorry, you ran out of guesses.  my number was #{goal}."
	return false
end

play