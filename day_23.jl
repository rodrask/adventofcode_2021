using Memoize, DataStructures, Parameters
Position = Tuple{Int,Int}

function Base.getindex(t::Tuple{Int, Int}, c::Symbol)
	c == :y ? t[1] : t[2]
end

State = Dict{Char, Vector{Position}}

buildroom(roomlevels::Vector{Int}, x::Int) = [(l,x) for l in roomlevels]
buildlowerrooms(roomlevels::Vector{Int}, pos::Position) = Set(filter(r ->  r[:y] > pos[:y], buildroom(roomlevels, pos[:x])))
buildupperrooms(roomlevels::Vector{Int}, pos::Position) = Set(filter(r ->  r[:y] < pos[:y], buildroom(roomlevels, pos[:x])))
@with_kw struct World 
	roomlevels::Vector{Int}
	height::Int = length(roomlevels)
	hallx::Vector{Int} = [1,2,4,6,8,10,11]
	hall::Set{Position} = Set((1, x) for x in hallx)
	roomsx::Vector{Int} = [3, 5, 7, 9]
	amphipods = ['A','B','C','D']
	weights = Dict(a=>10^(i-1) for (i,a) in enumerate(amphipods))
	
	rooms = union([buildroom(roomlevels,x) for x in roomsx]...)
	finalrooms = Dict{Char, Vector{Position}}( a=> buildroom(roomlevels, rx) for (a,rx) in zip(amphipods, roomsx))
	upperhall = Dict{Char,Position}(a=>(1, rx) for (a,rx) in zip(amphipods, roomsx))
	lowerrooms = Dict{Position, Set{Position}}(room => buildlowerrooms(roomlevels, room) for room in rooms)
	upperrooms = Dict{Position, Set{Position}}(room => buildupperrooms(roomlevels, room) for room in rooms)
end

isinhall(pos::Position) = pos[:y] == 1

const w1 = World(roomlevels=[3,2])
const w2 = World(roomlevels=[5,4,3,2])

function pathexists(w::World, from::Position, to::Position, occupied::Set{Position})
	sameroom = from[:x] == to[:x]
	fromhall = isinhall(from)
	tohall = isinhall(to)

	if sameroom || (fromhall && tohall)
		return false
	end
	xmin, xmax = minmax(from[:x],to[:x])
	result = !isblocked(w, occupied, from) && 
			!any(xmin <= ocx <= xmax for ocx in occupiedhallsx(occupied, from, to)) && 
			!isblocked(w, occupied, to)
	result
end

@memoize occupied(s::State) = Set(vcat(values(s)...))
occupiedhallsx(occupied::Set{Position}, from::Position, to::Position) = occupied |> op -> [pos[:x] for pos in op if pos!=from && pos!=to && (pos[:y]==1)]
isblocked(w::World, occupied::Set{Position}, pos::Position) = (pos[:y] > 2) && !isempty(w.upperrooms[pos] ∩ occupied)

isfinal(w::World, name::Char, pos::Position, filledpos::Vector{Position}) = 
		(pos ∈ w.finalrooms[name]) && (w.lowerrooms[pos] ⊆ filledpos)

@memoize function pathlength(from::Position, to::Position)
	dx = abs(from[:x] - to[:x])
	if dx == 0
		return abs(from[:y] - to[:y])
	else
		return dx + (from[:y] - 1) + (to[:y] - 1)
	end
end		

function mincost(w::World, state::State)
	result = 0
	for (name, positions) in pairs(state)
		weight = w.weights[name]
		currentupper = w.upperhall[name]
		misplaced = 1
		for pos in positions
			if !isfinal(w, name, pos, positions)
				if pos ∉ w.finalrooms[name]
					result += pathlength(pos, currentupper) * weight + misplaced
					misplaced += 1
				else
					result += (pos[:y] - 1) + 2 + w.height
				end
			end
		end
	end
	result
end

function nextmoves(w::World, state::State)
	result = []
	currentpositions = occupied(state)
	for name in w.amphipods
		positions = state[name]
		for (idx, pos) in enumerate(positions)
			if isfinal(w, name, pos, positions)
				continue
			end
			addhalls = true
			for to in w.finalrooms[name]
				if to ∉ currentpositions && pathexists(w, pos, to, currentpositions) && isfinal(w, name, to, positions)
					return [(name, idx, to, pathlength(pos, to) * w.weights[name])]
				end
			end
			if addhalls && !isinhall(pos)
				hallsto = [to for to in setdiff(w.hall, currentpositions) if pathexists(w, pos, to, currentpositions)]
				hallmoves = [(name, idx, to, pathlength(pos, to) * w.weights[name]) for to in hallsto]
				append!(result, hallmoves)
			end
		end
	end
	result
end

function domove(s::State, name::Char, idx::Int, to::Position)
	result = copy(s)
	newpositions = copy(result[name])
	newpositions[idx] = to
	sort!(newpositions)
	result[name] = newpositions
	result
end


function Astar(w::World, state::State; io::IO=stdout)
	bestsofar = nothing
	bestscore = typemax(Int)
	costdict = Dict{State, Int}([state=>0])
	queue = PriorityQueue{State, Int}([state=>mincost(w, state)])
	step = 0
	while !isempty(queue)
		step += 1
		state = dequeue!(queue)
		scost = costdict[state]
		for (name, idx, to, cost) in nextmoves(w, state)
			maybenext = domove(state, name, idx, to)
			nextscore = scost + cost
			costestimate = mincost(w, maybenext)
			if costestimate == 0 && nextscore < bestscore
				bestscore = nextscore
				bestsofar = maybenext
				show(io, state, w)
				println(io, "found final with score ", nextscore)
			elseif nextscore + costestimate < bestscore && nextscore < get(costdict, maybenext, typemax(Int))
				costdict[maybenext] = nextscore
				queue[maybenext] = nextscore + costestimate
			end
		end
		flush(io)
	end
	bestscore
end

function insert_part2(strmap::Vector{String})
	append!(strmap[1:3],["  #D#C#B#A#","  #D#B#A#C#"],strmap[4:5]) 
end

function load(strmap::Vector{String}, w::World=w1)
	result = Dict{Char, Vector{Position}}()
	shift = 1
	for x in w.hallx
		roompod = strmap[2][shift+x]
		if roompod ∈ w.amphipods
			push!(get!(result, roompod, Position[]), (1, x))
		end
	end
	for x in w.roomsx
		for y in w.roomlevels
			roompod = strmap[shift+y][shift+x]
			if roompod ∈ w.amphipods
				push!(get!(result, roompod, Position[]), (y, x))
			end
		end
	end
	foreach(sort!, values(result))
	State(result)
end

toci(p::Position) = CartesianIndex(p[:y],p[:x]+1)

show(s::State, w::World=w1) = show(stdout, s, w)
function show(io::IO, s::State, w::World=w1)
	height = length(w.roomlevels) + 1
	burrow = fill('#', (height,13))
	burrow[1,2:end-1] .= '.'
	burrow[w.rooms .|> toci] .= '.'
	burrow[1:height,1] = 1:height |> join |> collect
	for (name, positions) in pairs(s)
		burrow[positions .|> toci] .= name
	end
	println(io, "#12345678901#")
	[println(io, join(r)) for r in eachrow(burrow)]
	println(io, "  #########")
end

function runwithlogs(s::State, path="test.out",w::World=w1)
	open(path,"w") do io
		Astar(w, s, io=io)
	end
end

function main1()
	state = readlines("day_23_test.txt") |> load
	Astar(w1, state)
end

function main2()
	state = readlines("day_23_test.txt") |> insert_part2 |> s -> load(s,w2)
	Astar(w2, state)
end
