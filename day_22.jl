inputregex = r"(?<on>on|off) x=(?<xmin>\-?\d+)\.\.(?<xmax>\-?\d+),y=(?<ymin>\-?\d+)\.\.(?<ymax>\-?\d+),z=(?<zmin>\-?\d+)\.\.(?<zmax>\-?\d+)"

function parseLine(line::String)
	iparse(x) = parse(Int, x)
	m = match(inputregex, line)
	xrange = iparse(m[:xmin]):iparse(m[:xmax])
	yrange = iparse(m[:ymin]):iparse(m[:ymax])
	zrange = iparse(m[:zmin]):iparse(m[:zmax])

	CartesianIndices((xrange, yrange, zrange)), m[:on] == "on"
end

function toggleintersection!(area::CartesianIndices, dict::Dict{CartesianIndices, Int}, pair::Pair{CartesianIndices, Int})
	prevcube, value = pair
	intersection = area ∩ prevcube
	if length(intersection) > 0 
		dict[intersection] = get(dict, intersection, 0) -value
	end
end


function countcubes(input::Vector{Tuple{CartesianIndices{3,Tuple{UnitRange{Int64}, UnitRange{Int64}, UnitRange{Int64}}}, Bool}})
	cubecounter = Dict{CartesianIndices, Int}()
	step = 1
	for (area, value) in input
		currentcounter = Dict{CartesianIndices, Int}()
		foreach(p->toggleintersection!(area, currentcounter, p), pairs(cubecounter))
		if value
			cubecounter[area] = 1
		end
		mergewith!(+, cubecounter, currentcounter)
		delete!.((cubecounter,), [k for (k,v) in pairs(cubecounter) if v == 0])
		step += 1
	end
	sum((length(c)*v for (c, v) in pairs(cubecounter)))
end

function main1()
	smallcube = CartesianIndices((-50:50,-50:50,-50:50))
	input = readlines("day_22.txt") .|> parseLine |> 
		cubes -> map(cs -> (smallcube ∩ cs[1],cs[2]), cubes) |>
		cubes -> filter(cs -> length(cs[1]) > 0, cubes)
	println(countcubes(input))
end

function main2()
	input = (readlines("day_22.txt") .|> parseLine)
	println(countcubes(input))
end

