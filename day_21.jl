using LinearAlgebra
inputregex = r"Player \d+ starting position: (?<pos>\d+)"

readinput(path::String) = [match(inputregex, l) for l in readlines(path)] .|> m -> Player(parse(Int, m[:pos]), 0, 0, 1)

struct Player
	position::Int
	score::Int
	stepsdone::Int
	multiplier::Int
end

mutable struct Dice
	state::Int
	nrolls::Int
	Dice() = new(1, 0)
end

function roll!(dice::Dice)
	result = dice.state
	dice.nrolls += 1
	dice.state = dice.state == 100 ? 1 : dice.state + 1
	result
end

win(player::Player, winscore::Int) = player.score >= winscore

function move(player::Player, move::Int, multiplier::Int)
	newposition = (player.position + move - 1) % 10 + 1
	Player(newposition, player.score+newposition, player.stepsdone+1, player.multiplier * multiplier)
end

multpliers = let 
	result = zeros(Int, 9)
	foreach(s -> result[sum(s)]+=1, Iterators.product(1:3,1:3,1:3))
	result
end

splitmove(p::Player) = [move(p,s, multpliers[s]) for s in 3:9]

function countsteps(p::Player, winscore::Int)
	activepaths = [p]
	actives = zeros(Int, 10)
	wins = zeros(Int, 10)
	while !isempty(activepaths)
		current = pop!(activepaths)
		for next in splitmove(current)
			if win(next, winscore)
				wins[next.stepsdone] += next.multiplier
			else
				actives[next.stepsdone] += next.multiplier
				pushfirst!(activepaths, next)
			end
		end
	end
	wins, actives
end

answer(p::Player,d::Dice) = p.score * d.nrolls

function main1()
	winscore = 1000
	p1, p2 = readinput("day_21.txt")
	dice = Dice()
    while true
		m1, m2, m3 = roll!(dice), roll!(dice), roll!(dice)
		p1 = move(p1, m1+m2+m3, 1)
		if win(p1, winscore)
			return answer(p2, dice)
		end
		m1, m2, m3 = roll!(dice), roll!(dice), roll!(dice)
		p2 = move(p2, m1+m2+m3, 1)
		if win(p2, winscore)
			return answer(p1, dice)
		end
	end
end

function main2()
	winscore = 21
	p1, p2 = readinput("day_21.txt")
	w1, a1 = countsteps(p1, winscore)
	w2, a2 = countsteps(p2, winscore)

	win1 = dot(w1[2:end], a2[1:end-1])
	win2 = dot(w2, a1)
	max(win1,win2)
end

println(main1())
println(main2())
