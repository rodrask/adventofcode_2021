struct Point
    x::Int
    y::Int
 end
struct Line
    start::Point
    finish::Point
end

function parseLine(l::String)
    s,f = split(l, " -> ")
    s_x, s_y = split(s, ",") .|> d -> parse(Int, d)
    f_x, f_y = split(f, ",") .|> d -> parse(Int, d)
    Line(Point(s_x+1, s_y+1), Point(f_x+1, f_y+1))
end

isStraightLine(line::Line) = line.start.x == line.finish.x || line.start.y == line.finish.y
fieldSize(lines::AbstractVector{Line}) = 
    ( 
        maximum(l->max(l.start.x, l.finish.x), lines),
        maximum(l->max(l.start.y, l.finish.y), lines)
    )

safeRange(x1::Int,x2::Int) = ifelse(x1 <= x2, x1:x2, x1:-1:x2)
lineIndices(l::Line) = CartesianIndex.(safeRange(l.start.x, l.finish.x), safeRange(l.start.y, l.finish.y))

fill!(field::AbstractMatrix, line::Line) = foreach(ci -> field[ci] += 1, lineIndices(line))
countOvelaps(field::AbstractMatrix) = count(v -> v>1, field)

function main1()
    lines = readlines("day_5.txt") .|> parseLine |> lines -> filter(isStraightLine, lines)
    dims = fieldSize(lines)
    field = zeros(Int, dims)
    foreach(l->fill!(field, l), lines)
    println("Ovelaps: $(countOvelaps(field))")
end

function main2()
    lines = readlines("day_5.txt") .|> parseLine
    dims = fieldSize(lines)
    field = zeros(Int, dims)
    foreach(l->fill!(field, l), lines)
    println("Ovelaps: $(countOvelaps(field))")
end

main1()
main2()