abstract type AbstractPosition end
mutable struct Position <: AbstractPosition
	depth::Int
	x::Int
	Position() = new(0,0)
end

forward(pos::Position, value::Int) = pos.x += value
up(pos::Position, value::Int) = pos.depth -= value
down(pos::Position, value::Int) = pos.depth += value

mutable struct PositionV2 <: AbstractPosition
	depth::Int
	x::Int
	aim::Int
	PositionV2() = new(0,0,0)
end

forward(pos::PositionV2, value::Int) = (pos.x += value; pos.depth += value * pos.aim)
up(pos::PositionV2, value::Int) = pos.aim -= value
down(pos::PositionV2, value::Int) = pos.aim += value

moves = Dict(
	"forward"=>forward,
	"up" => up,
	"down" => down)

function move(p::AbstractPosition, direction::AbstractString, value::Int)
	moves[direction](p, value)
end

function parseLine(line::AbstractString)
	direction, value = split(line, " ")
	return (dir=direction, val=parse(Int, value))
end

doWork(p::AbstractPosition) = readlines("day_2.txt") .|> parseLine .|> m -> move(p, m.dir, m.val)

function main1()
	position = Position()
	doWork(position)
	println(position.depth * position.x)
end

function main2()
	position = PositionV2()
	doWork(position)
	println(position.depth * position.x)
end

main1()
main2()
