using Memoize, DataStructures
Position = NamedTuple{(:y, :x), Tuple{Int,Int}}
Amphipod = NamedTuple{(:name, :pos), Tuple{Char,Position}}
State = Dict{Char, Vector{Position}}

hallx = [1,2,4,6,8,10,11]
hall = [(y=1,x=x) for x in hallx]

roomsx = [3,5,7,9]
roomlevels = (2,3)
room(x::Int) = [(y=l,x=x) for l in roomlevels]
rooms = vcat([room(x) for x in roomsx]...)
roomhall(room::Position) = (y=1,x=room[:x])

burrow = vcat(hall, rooms)

amphipods = ['A','B','C','D']
weights = Dict(a=>10^(i-1) for (i,a) in enumerate(amphipods))
finalrooms = Dict(a=>room(rx) for (a,rx) in zip(amphipods, roomsx))

function directsteps(from::Int, to::Int)
	step = from < to ? 1 : -1
	collect(from+step:step:to)
end

@memoize function path(from::Position, to::Position)
	if from == to
		return Position[]
	end
	sameroom = from[:x] == to[:x]
	fromhall = from[:x] == 1
	tohall = to[:x] == 1
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

@memoize pathcost(name::Char, path::Vector{Position}) = length(path) * weights[name]

occupied(s::State) = vcat(values(s)...)
candidates(s::State) = filter(b -> b ∉ occupied(s), burrow)

isblocked(s::State, pos::Position) = (pos[:y] == 3) && (y=2, x=pos[:x]) ∈ occupied(s)
isfeasible(state::State, path::Vector{Position}) = isempty(occupied(state) ∩ path)

@memoize isfinal(name::Char, pos::Position) =  pos ∈ finalrooms[name]
@memoize isdeepfinal(name::Char, pos::Position) = isfinal(name, pos) && (pos[:y] == 3)

isfinal(state::State) = all(isfinal(name, p1) && isfinal(name, p2) for (name, (p1, p2)) in pairs(state))

@memoize function mincost(state::State)
	result = 0
	for (name, (p1,p2)) in pairs(state)
		# println(name," ", p1, " ", p2)
		f1,f2 = finalrooms[name]
		# println(f1, " ", f2)
		# println(pathcost(name, path(p1,f1)), " ",pathcost(name, path(p2,f2)))
		# println(pathcost(name, path(p1,f2)), " ",pathcost(name, path(p2,f1)))
		result += min(pathcost(name, path(p1,f1)) + pathcost(name, path(p2,f2)),
			pathcost(name, path(p1,f2)) + pathcost(name, path(p2,f1)))
	end
	result
end

function nextmoves(state::State)
	cands = candidates(state)
	result = []
	for name in amphipods
		ps = state[name]
		if all(isfinal(name, p) for p in ps)
			continue
		end
		for (idx, p) in zip((1,2), ps)
			if isblocked(state, p) || isdeepfinal(name, p)
				continue
			end
			pathcandidates = cands |> cs -> map(c -> path(p, c), cs) |> paths -> filter(p -> isfeasible(state, p), paths)
			append!(result, [(name, idx, path[end], pathcost(name,path)) for path in pathcandidates])
		end
	end
	result
end

function domove(s::State, name::Char, idx::Int, to::Position)
	result = deepcopy(s)
	result[name][idx] = to
	result
end


function Astar(state::State, maxsteps::Int=100, io::IO=stdout)
	bestsofar = nothing
	bestscore = typemax(Int)
	queue = PriorityQueue{State, Int}()
	queue[state] = 0
	step = 1
	realscore = 12521
	while !isempty(queue) && step < maxsteps
		state, scost = peek(queue)
		delete!(queue, state)
		for (name, idx, to, cost) in nextmoves(state)
			maybenext = domove(state, name, idx, to)
			costestimate = mincost(maybenext)
			nextscore = scost + cost + costestimate

			if costestimate == 0 && nextscore <= bestscore
				bestscore = nextscore
				bestsofar = maybenext
				println(io, "found final with score ", nextscore)
			elseif nextscore <= min(bestscore, get(queue, maybenext, typemax(Int)), realscore)
				queue[maybenext] = nextscore
				show(io, maybenext)
				println(io, "Moving ",name," to ",to)
				println(io, "State score: ", scost + cost," cost estimate ", costestimate, " total ",nextscore, "\n")
			end
		end
		step += 1
	end
	flush(io)
	bestscore
end

function load(strmap::Vector{String})
	result = Dict{Char, Vector{Position}}()
	shift = 1
	for x in hallx
		roompod = strmap[2][shift+x]
		if roompod ∈ amphipods
			push!(get!(result, roompod, Position[]), (y=1,x=x))
		end
	end
	for x in roomsx
		for y in roomlevels
			roompod = strmap[shift+y][shift+x]
			if roompod ∈ amphipods
				push!(get!(result, roompod, Position[]), (y=y,x=x))
			end
		end
	end
	State(result)
end

toci(p::Position) = CartesianIndex(p[:y],p[:x]+1)

function show(io::IO, s::State)
	burrow = fill('#', (3,13))
	burrow[1,2:end-1] .= '.'
	burrow[rooms .|> toci] .= '.'
	burrow[1:3,1] = ['1','2','3']
	for (name, (p1,p2)) in pairs(s)
		burrow[[p1,p2] .|> toci] .= name
	end
	println(io, "#12345678901#")
	[println(io, join(r)) for r in eachrow(burrow)]
	println(io, "  #########")
end
