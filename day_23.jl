using Memoize, DataStructures, Parameters
Position = NamedTuple{(:y, :x), Tuple{Int,Int}}
Amphipod = NamedTuple{(:name, :pos), Tuple{Char,Position}}
State = Dict{Char, Vector{Position}}

@with_kw struct World 
	roomlevels::Vector{Int}

	hallx::Vector{Int} = [1,2,4,6,8,10,11]
	hall::Vector{Position} = [(y=1,x=x) for x in hallx]
	roomsx::Vector{Int} = [3,5,7,9]
	amphipods = ['A','B','C','D']
	weights = Dict(a=>10^(i-1) for (i,a) in enumerate(amphipods))
end

@memoize room(w::World, x::Int) = [(y=l,x=x) for l in w.roomlevels]
@memoize rooms(w::World) = vcat([room(w,x) for x in w.roomsx]...)

@memoize lowerrooms(w::World, pos::Position) = [r for r in room(w,pos[:x]) if r[:y] > pos[:y]]
@memoize upperrooms(w::World, pos::Position) = [r for r in room(w,pos[:x]) if r[:y] < pos[:y]]

@memoize finalrooms(w::World) = Dict(a=>room(w, rx) for (a,rx) in zip(w.amphipods, w.roomsx))

isinhall(pos::Position) = pos[:y] == 1

w1 = World(roomlevels=[3,2])
w2 = World(roomlevels=[5,4,3,2])

function directsteps(from::Int, to::Int)
	step = from < to ? 1 : -1
	collect(from+step:step:to)
end

@memoize function path(from::Position, to::Position)
	if from == to
		return Position[]
	end
	sameroom = from[:x] == to[:x]
	fromhall = isinhall(from)
	tohall = isinhall(to)

	if sameroom
		return [(y=y,x=from[:x]) for y in directsteps(from[:y], to[:y])] 
	elseif fromhall & tohall
		return [(y=1,x=x) for x in directsteps(from[:x], to[:x])] 
	elseif fromhall && ! tohall
		return vcat([(y=1,x=x) for x in directsteps(from[:x], to[:x])],
					[(y=y, x=to[:x]) for y in directsteps(1, to[:y])])
	elseif !fromhall && tohall
		return vcat([(y=y, x=from[:x]) for y in directsteps(from[:y], 1)],
					[(y=1,x=x) for x in directsteps(from[:x], to[:x])])
	else
		return vcat([(y=y, x=from[:x]) for y in directsteps(from[:y], 1)],
					[(y=1,x=x) for x in directsteps(from[:x], to[:x])],
					[(y=y, x=to[:x]) for y in directsteps(1, to[:y])])
	end
end

@memoize pathcost(weight::Int, path::Vector{Position}) = length(path) * weight

@memoize occupied(s::State) = vcat(values(s)...)
isblocked(w::World, s::State, pos::Position) = (pos[:y] > 2) && !isempty(upperrooms(w, pos) ∩ occupied(s))
isfeasible(state::State, path::Vector{Position}) = isempty(occupied(state) ∩ path)


@memoize isfinal(w::World, name::Char, pos::Position, filledpos::Vector{Position}) = 
		(pos ∈ finalrooms(w)[name]) && (lowerrooms(w, pos) ⊆ filledpos)

@memoize function mincost(w::World, state::State)
	result = 0
	for (name, positions) in pairs(state)
		weight = w.weights[name]
		fhighest = finalrooms(w)[name][end]
		misplaced = 0
		for pos in positions
			if !isfinal(w, name, pos, positions)
				result += (pathcost(weight, path(pos, fhighest)) + misplaced)
				misplaced += 1
			end
		end

		# result += min(pathcost(weight, path(p1,f1)) + pathcost(weight, path(p2,f2)),
		# 	pathcost(weight, path(p1,f2)) + pathcost(weight, path(p2,f1)))
	end
	result
end

function nextmoves(w::World, state::State)
	result = []
	currentpositions = occupied(state)
	for name in reverse(w.amphipods)
		positions = state[name]
		for (idx, pos) in enumerate(positions)
			if isblocked(w, state, pos) || isfinal(w, name, pos, positions)
				continue
			end
			for finalroom in finalrooms(w)[name]
				frpath = path(pos, finalroom)
				if isfeasible(state, frpath)
					push!(result, (name, idx, finalroom, pathcost(w.weights[name], frpath)))
				end
			end
			if !isinhall(pos)
				hallpaths = [path(pos, h) for h in setdiff(w.hall, currentpositions)]
				hallmoves = [(name, idx, hp[end], pathcost(w.weights[name], hp)) for hp in hallpaths if isfeasible(state, hp)]
				append!(result, hallmoves)
			end
		end
	end
	result
end

function domove(s::State, name::Char, idx::Int, to::Position)
	result = deepcopy(s)
	result[name][idx] = to
	sort!(result[name])
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
				println(io, "found final with score ", nextscore)
			elseif nextscore + costestimate < bestscore && nextscore < get(costdict, maybenext, typemax(Int))
				costdict[maybenext] = nextscore
				queue[maybenext] = nextscore + costestimate
				# println(io, "Moving ",name," to ",to, " step ", step, " State score: ", scost + cost, " total ",nextscore)
				# show(io, maybenext, w)
			else
				# println(io, "Reject step ",name," to ",to, "State score: ", scost + cost, " total ",nextscore)
				# show(io, maybenext, w)
			end
		end
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
			push!(get!(result, roompod, Position[]), (y=1,x=x))
		end
	end
	for x in w.roomsx
		for y in w.roomlevels
			roompod = strmap[shift+y][shift+x]
			if roompod ∈ w.amphipods
				push!(get!(result, roompod, Position[]), (y=y,x=x))
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
	burrow[rooms(w) .|> toci] .= '.'
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