using OffsetArrays

charmap = Dict('.'=>0, '#'=>1)
function readieavector(io)
	BitVector(charmap[c] for c in readline(io) |> collect)
end

function readimage(io)
	lines = readlines(io)
	n_rows = length(lines)
	n_cols = length(first(lines))
	result = zeros(Int, (n_rows, n_cols))
	for (idx, line) in enumerate(lines)
		vector = collect(line) .|> c -> charmap[c]
		result[idx,:] = vector
	end
	BitMatrix(result)
end

function readinput(path)
	open(path) do io
		ieavector = readieavector(io)
		readline(io)
		image = readimage(io)
		return ieavector, image
	end
end

const step = CartesianIndex(1,1)
const traverseorder = [1, 4, 7, 2, 5, 8, 3, 6, 9]
function enhancestep(ieavector::BitVector, img::BitMatrix, valueoninf::Bool=false)
	n_rows, n_cols = size(img)
	result = OffsetArray(falses(n_rows+2, n_cols+2), 0:n_rows+1, 0:n_cols+1)
	for idx in CartesianIndices(result)
		ieaidx = 0
		for (o, nidx) in zip(traverseorder, idx-step:idx+step)
			imgvalue = (1 <= nidx.I[1] <= n_rows) && (1 <= nidx.I[2] <= n_cols) ? img[nidx] : valueoninf
			ieaidx += imgvalue << (9-o)
		end
		result[idx] = ieavector[ieaidx+1]
	end
	newvalueoninf = valueoninf == 0 ? ieavector[1] : ieavector[end]
	OffsetArrays.no_offset_view(result), newvalueoninf
end

function main1()
	vec, img = readinput("day_20.txt")
	infvalue = false
	for _ in 1:2
		img, infvalue = enhancestep(vec, img, infvalue)
	end
	println(sum(img))
end

function main2()
	vec, img = readinput("day_20.txt")
	infvalue = false
	for _ in 1:50
		img, infvalue = enhancestep(vec, img, infvalue)
	end
	println(sum(img))
end

main1()
main2()
