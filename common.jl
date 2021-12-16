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

function getBorderCheckFunc(m::AbstractMatrix)
	rows, cols = size(m)
	borderCheck(idx::CartesianIndex) = (1 <= idx.I[1] <= rows) && (1 <= idx.I[2] <= cols)
end

const yMove = CartesianIndex{2}(1,0)
const xMove = CartesianIndex{2}(0,1)
function safeNeighbours4(m::AbstractMatrix)
	myneighbours(idx::CartesianIndex) = filter(getBorderCheckFunc(m), [idx-yMove, idx+yMove, idx-xMove, idx+xMove])
end

function safeNeighbours8(m::AbstractMatrix)
	f = CartesianIndex(1,1)
	l = CartesianIndex(size(m))
	myneighbours(idx::CartesianIndex{2}) = [i for i in max(f, idx-f):min(l, idx+f) if i != idx]
end


	