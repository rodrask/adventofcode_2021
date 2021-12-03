parseLine(l::String) = split(l, "") .|> c -> parse(Int, c)

function bitarr_to_int(arr::AbstractVector{Bool})
	result = 0
    v = 1
    for i in view(arr,length(arr):-1:1)
        result += v*i
        v <<= 1
    end 
    result
end

most_common_bit(r::AbstractVector{Bool}) = sum(r) >= length(r) / 2

find_idxs(v1::AbstractMatrix, v2::AbstractVector) = [idx for (idx,r) in enumerate(eachrow(v1)) if r == v2]

function find_rating(vectors::BitMatrix, most_common_bit_mode=true)
	prefix_size = 1
	match_vector::BitVector = []
	while size(vectors, 1) > 1
		prefix_column = @view vectors[:,prefix_size]
		next_bit = most_common_bit(prefix_column)
		if !most_common_bit_mode
			next_bit = !next_bit
		end

		push!(match_vector, next_bit)
		match_idxs = find_idxs((@view vectors[:,1:prefix_size]), match_vector)
		prefix_size += 1
		vectors = vectors[match_idxs, :]
	end	
	bitarr_to_int(@view vectors[1,:])
end


function main1()
	vectors = readlines("day_3.txt") .|> parseLine |> v -> hcat(v...) |> permutedims |> BitMatrix
	gamma_rate = most_common_bit.(eachcol(vectors))
	epsilon_rate = .~(gamma_rate)
	bitarr_to_int(gamma_rate) * bitarr_to_int(epsilon_rate)
end

function main2()
	vectors = readlines("day_3.txt") .|> parseLine |> v -> hcat(v...) |> permutedims |> BitMatrix
	oxygen_rating = find_rating(vectors)
	co2_rating = find_rating(vectors, false)
    oxygen_rating * co2_rating
end

println(main1())
println(main2())
