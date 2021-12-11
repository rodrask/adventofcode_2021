using Statistics
const openbrackets =  collect("([{<")
const closebrackets = collect(")]}>")
const pairbrackets = Dict(zip(openbrackets, closebrackets))

const scores4WrongBrackets = Dict(zip(closebrackets, [3,57,1197,25137]))
const scores4Autocomplete = Dict(zip(closebrackets, 1:4))

function parseBracketLine(line::String)
	stack = Char[]
	for bracket in collect(line)
		if haskey(pairbrackets, bracket)
			push!(stack, bracket)
		else
			if pairbrackets[pop!(stack)] != bracket
				return scores4WrongBrackets[bracket], 0
			end
		end
	end
	isempty(stack) ? (0,0) : (0, autocompleteScore(stack))
end

autocompleteScore(openstack::Vector{Char}) = 
	foldl((x,y)->5*x+y, 
	reverse([scores4Autocomplete[pairbrackets[b]] for b in openstack]))

function main1()
	(score for (score, _) in parseBracketLine.(eachline("day_10.txt"))) |> sum
end

function main2()
	(autocompleteScore for (score, autocompleteScore) in parseBracketLine.(eachline("day_10.txt")) if score == 0) |> 
	median |> m->floor(Int, m) 
end

println(main1())
println(main2())
