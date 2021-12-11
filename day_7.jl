using Statistics
parsePositions(line::String) = split(line, ",") .|> p -> parse(Int, p)

function main1()
	crabs = readline("day_7.txt") |> parsePositions
	align = round(Int, median(crabs))
	error = crabs .- align .|> abs |> sum
	println("Align at $align with cost $error")
end

cost(positions::AbstractVector{Int}, align::Int) = positions .- align .|> abs |> errs -> map(x -> x*(x+1) ÷ 2, errs) |> sum

function main2()
	crabs = readline("day_7.txt") |> parsePositions
	align = floor(Int,mean(crabs))
	aligns = [align, align + 1]
	costs = cost.((crabs,), aligns)
	cost_idx = argmin(costs)
	println("Align at $(aligns[cost_idx]) with cost $(costs[cost_idx])")
end

main1()
main2()
