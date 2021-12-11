MAX_AGE = 9
parseAges(line::String) = split(line, ",") .|> a -> parse(Int, a)

function ages2Hist(ages::AbstractVector{Int})
	hist = zeros(Int, MAX_AGE)
	for age in ages
		hist[age+1] += 1
	end
	hist
end

function hist2Ages(agesHist::AbstractVector{Int})
	items::Vector{Int} = []
	for (i,c) in enumerate(agesHist)
		c_ages = repeat([i-1], c)
		append!(items, c_ages)
	end
	items
end

function step!(agesHist::AbstractVector{Int})
	newbornFishes = agesHist[1]
	for idx in 2:MAX_AGE
		agesHist[idx-1] = agesHist[idx]
	end
	agesHist[MAX_AGE] = newbornFishes
	agesHist[MAX_AGE-2] += newbornFishes
end
totalFishes(agesHist::AbstractVector{Int}) = sum(agesHist)

function runSimulation(ages::AbstractVector{Int}, days::Int)
	agesHist = ages2Hist(ages)
	for _ in 1:days
		step!(agesHist)
	end
	totalFishes(agesHist)
end

function main1()
	agesHist = readline("day_6.txt") |> parseAges
	fishesAfter80 = runSimulation(agesHist, 80)
	println("After 80 days there are total $(fishesAfter80) fishes")
end

function main2()
	agesHist = readline("day_6.txt") |> parseAges
	fishesAfter256 = runSimulation(agesHist, 256)
	println("After 256 days there are total $(fishesAfter256) fishes")
end


main1()
main2()
