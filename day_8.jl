N_SEGMENTS = 7
SEGMENTS = "abcdefg"
letter2idx = Dict([l=>i for (i,l) in enumerate(SEGMENTS)])
SIMPLE_DIGITS = [1,4,7,8]

function vectorize(input::AbstractString)
	result = zeros(Int, N_SEGMENTS)
	for l in input
		result[letter2idx[l]] = 1
	end
	BitVector(result)
end

letterize(vector::BitVector) = SEGMENTS[findall(p->p>0,vector)]

enum_cols = enumerate ∘ eachcol

# 0 to 9 in segments
const correctCodes =  [
	"abcefg", 
	"cf",  "acdeg",  "acdfg", 
	"bcdf","abdfg",  "abdefg",
	"acf", "abcdefg","abcdfg"
]
const codeMatrix = hcat(vectorize.(correctCodes)...)

function parseLine(line::String)
	segments, digits = split(line, " | ")
	(split(segments, " ") .|> vectorize, split(digits, " ") .|> vectorize)
end

function find3(n_235, n_1)
	idx_3 = first(idx for (idx, n) in enum_cols(n_235) if n .* n_1 == n_1)
	n_235[:, idx_3], @view n_235[:, 1:end .!= idx_3]
end

function find6(n_069, n_1)
	idx_6 = first(idx for (idx, n) in enum_cols(n_069) if n .* n_1 != n_1)
	n_069[:, idx_6], @view n_069[:, 1:end .!= idx_6]
end

select_09(n_09, n_3) =    (n_09[:, 1] .* n_3 != n_3)  ? n_09 : @view n_09[:, [2,1]]
select_25(n_25, n_6) = (sum(n_25[:, 1] .* n_6) == 4) ? n_25 : @view n_25[:, [2,1]]

function solve(digits::AbstractMatrix{Bool})
	result = zeros(Bool, size(digits))
	segmentsSum = dropdims(sum(digits, dims=1); dims=1)
	correctSums = dropdims(sum(codeMatrix, dims=1); dims=1)
	result[:,SIMPLE_DIGITS .+ 1] = digits[:, [findfirst(s-> s==correctSums[d+1], segmentsSum) for d in SIMPLE_DIGITS]]

	n_235 = @view digits[:, segmentsSum .== 5]
	n_069 = @view digits[:, segmentsSum .== 6] 

	n_1 = result[:,1+1]

	result[:, 3+1], n_25 = find3(n_235, n_1)
	result[:, 6+1], n_09 = find6(n_069, n_1)

	result[:,[0+1,9+1]] .= select_09(n_09, result[:, 3+1])
	result[:,[2+1,5+1]] .= select_25(n_25, result[:, 6+1])
	result
end

function apply(target, solution)
	digits = (first(idx for (idx, d) in enum_cols(solution) if d == digit) - 1 for digit in target)
	foldl((x,y)->10*x+y, digits)
end

function main1()
	digits = Vector{BitVector}()
	for line in readlines("day_8.txt")
		_, line_digits = parseLine(line)
		append!(digits, line_digits)
	end
	digits = hcat(digits...)
	segmentsSum = sum(digits, dims=1)
	correctSums = sum(codeMatrix, dims=1)
	result = sum(count(s-> s == correctSums[1+d], segmentsSum) for d in SIMPLE_DIGITS)
	println(result)
end

function main2()
	result = 0
	for line in readlines("day_8.txt")
		all_digits, target_digits = parseLine(line)
		digits = solve(hcat(all_digits...))
		result += apply(target_digits, digits)
	end
	println(result)
end

main1()
main2()
