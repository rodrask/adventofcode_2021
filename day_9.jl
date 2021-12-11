function readMap(path)
	lines = readlines(path)
	n_rows = length(lines)
	n_cols = length(first(lines))
	result = zeros(Int, (n_rows, n_cols))
	for (idx, line) in enumerate(lines)
		vector = collect(line) |> chars -> parse.(Int, chars)
		result[idx,:] = vector
	end
	result
end

function getBorderCheckFunc(m::AbstractMatrix{Int})
	rows, cols = size(m)
	borderCheck(idx::CartesianIndex) = (1 <= idx.I[1] <= rows) && (1 <= idx.I[2] <= cols)
	borderCheck
end

const yMove = CartesianIndex{2}(1,0)
const xMove = CartesianIndex{2}(0,1)

safeNeighbours(m::AbstractMatrix{Int}) = (
	myNeighbours(idx::CartesianIndex) = filter(getBorderCheckFunc(m), [idx-yMove, idx+yMove, idx-xMove, idx+xMove]))

function lowerPointsIdxs(map::AbstractMatrix{Int})
	myNeighbours = safeNeighbours(map)
	Iterators.filter(idx -> all((@view map[myNeighbours(idx)]) .> map[idx]), keys(map))
end

function measureBasinSize(map::AbstractMatrix{Int}, lp::CartesianIndex{2})
	result = Set{CartesianIndex{2}}()
	frontier = CartesianIndex{2}[]
	myNeighbours = safeNeighbours(map)
	
	push!(result, lp)
	push!(frontier, lp)
	while !isempty(frontier)
		current = pop!(frontier)
		nns = filter(idx -> (idx ∉ result) && map[current] < map[idx] < 9, myNeighbours(current))
		union!(result, nns)
		append!(frontier, nns)
	end
	length(result)
end

lowerPointsValues(map::AbstractMatrix{Int}) = map[collect(lowerPointsIdxs(map))]
basinsSizes(map::AbstractMatrix{Int}) = (measureBasinSize(map, idx) for idx in lowerPointsIdxs(map))

function main1()
	readMap("day_9.txt") |> lowerPointsValues |> lv -> sum(lv) + length(lv)
end

function main2()
	readMap("day_9.txt") |> basinsSizes |> collect |> bs -> partialsort!(bs, 1:3, rev=true) |> prod
end

println(main1())
println(main2())
