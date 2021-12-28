include("common.jl")
EAST=1
SOUTH=2

eaststep = CartesianIndex(0, 1)
southstep = CartesianIndex(1, 0)
ch2int = Dict('.'=>0,'>'=>EAST,'v'=>SOUTH)
int2ch = Dict(p[2]=>p[1] for p in pairs(ch2int))
circularmove(size::Tuple{Int,Int}, step::CartesianIndex) = result(idx::CartesianIndex) = mod1.((idx+step).I, size) |> CartesianIndex

function step(map::Matrix{Int}, eastmove::Function, southmove::Function)
	intermresult = copy(map)
	for idx in eachindex(IndexCartesian(), map)
		value = map[idx]
		if value == EAST && map[eastmove(idx)] == 0
			intermresult[idx] = 0
			intermresult[eastmove(idx)] = EAST
		end
	end
	
	result = copy(intermresult)
	for idx in eachindex(IndexCartesian(), intermresult)
		value = intermresult[idx]
		if value == SOUTH && intermresult[southmove(idx)] == 0
			result[idx] = 0
			result[southmove(idx)] = SOUTH
		end
	end
	result
end

function show(map::Matrix{Int})
	foreach(row -> println(join([int2ch[v] for v in row])), eachrow(map))
end

function main1()
	map = readMap("day_25.txt", c->ch2int[c])
	eastmove = circularmove(size(map), eaststep)
	southmove = circularmove(size(map), southstep)
	nextmap = step(map, eastmove, southmove)
	steps = 1
	while map != nextmap
		map = nextmap
		nextmap = step(map, eastmove, southmove)
		steps += 1
	end
	steps
end
