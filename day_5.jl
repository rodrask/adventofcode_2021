using DelimitedFiles

struct Point
    x::Int
    y::Int
 end
struct Line
    start::Point
    finish::Point
end

function parseLine(l::String)
    s,f = split(l," -> ")
    s_x, s_y = split(s,",") .|> d -> parse(Int, d)
    f_x, f_y = split(f,",") .|> d -> parse(Int, d)
    Line(Point(s_x, s_y), Point(f_x, f_y))
end

isStraightLine(line::Line) = line.start.x == line.finish.x || line.start.y == line.finish.y
function fieldSize(lines::AbstractVector{Line})
    max_x = maximum(l->max(l.start.x, l.finish.x), lines)
    max_y = maximum(l->max(l.start.y, l.finish.y), lines)
    (max_x+1 ,max_y+1)
end

safeRange(x1::Int,x2::Int) = ifelse(x1 <= x2, (x1+1):(x2+1), (x1+1):-1:(x2+1))
lineIndices(l::Line) = CartesianIndex.(safeRange(l.start.x, l.finish.x), safeRange(l.start.y, l.finish.y))

function fill!(field::AbstractMatrix, line::Line)
    for ci in lineIndices(line)
        field[ci] += 1
    end
end

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