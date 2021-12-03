
function main1()
	inc = readlines("day_1.txt") |> 
		l -> parse.(Int, l) |> 
		diff |> 
		delta -> count(d -> d > 0, delta)
	println(inc)
end

function sliding_sum(v, w::Int)
	result = similar(v, length(v)-(w-1))
	for idx in eachindex(result)
		result[idx] = sum(v[idx:(idx+w-1)])
	end
	return result
end

function main2()
	inc = readlines("day_1.txt") |> 
		l -> parse.(Int, l) |>
		items -> sliding_sum(items, 3) |>
		diff |> 
		delta -> count(d -> d > 0, delta)
	println(inc)
end

main1()
main2()
