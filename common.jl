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
