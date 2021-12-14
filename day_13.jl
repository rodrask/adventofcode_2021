function loadSheet(io::IOStream)
    indicies = CartesianIndex{2}[]
    rows, cols = 0, 0
    for line in eachline(io)
        if isempty(line)
            break
        end
        c, r = split(line, ",") .|> v -> parse(Int, v)
        push!(indicies, CartesianIndex(r+1,c+1))
        rows, cols = max(rows, r+1), max(cols, c+1)
    end
    result = falses(rows, cols)
    result[indicies] .= true
    result
end

struct VerticalFold
    axis::Int
end
struct HorizontalFold
    axis::Int
end

parsefold(rm::RegexMatch) = rm[:dir]=="x" ? VerticalFold(parse(Int, rm[:axis])+1) : 
                                            HorizontalFold(parse(Int, rm[:axis])+1)

const foldregex = r"fold along (?<dir>[xy])=(?<axis>\d+)"
loadInstructions(io::IOStream) = [parsefold(match(foldregex, line)) for line in readlines(io)]

printSheet(sheet::BitMatrix) = foreach(row -> println(join([v ? '*' : ' ' for v in row])), eachrow(sheet))

applyFold(m::BitMatrix, f::VerticalFold) =   (@view m[:, 1:(f.axis-1)]) .| (@view m[:, end:-1:(f.axis+1)])
applyFold(m::BitMatrix, f::HorizontalFold) = (@view m[1:(f.axis-1), :]) .| (@view m[end:-1:(f.axis+1), :])

function main1()
    open("day_13.txt") do io
        sum(applyFold(loadSheet(io), loadInstructions(io)[1]))
    end
end

function main2()
    open("day_13.txt") do io
        sheet = loadSheet(io)
        folds = loadInstructions(io)
        sheet = foldl((sheet, fold) -> applyFold(sheet, fold), folds;init=sheet)
        printSheet(sheet)
    end
end

println(main1())
main2()