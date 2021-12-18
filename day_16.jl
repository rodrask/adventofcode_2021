abstract type Expression end

LITERAL = 4
struct Literal <: Expression
    version::Int
    value::Int
end

struct Operator <: Expression
    version::Int
    opcode::Int
    expressions::Vector{Expression}
end

sumversions(expr::Literal) = expr.version
sumversions(expr::Operator) = expr.version + sum(sumversions.(expr.expressions))

value(expr::Literal) = expr.value
value(expr::Operator) = opcodes[expr.opcode](expr.expressions .|> value)

opcodes = Dict(
    0 => sum,
    1 => prod,
    2 => minimum,
    3 => maximum,
    5 => vs -> Int(vs[1] > vs[2]),
    6 => vs -> Int(vs[1] < vs[2]),
    7 => vs -> Int(vs[1] == vs[2])
)

mutable struct ParseState
    data::BitVector
    offset::Int
    ParseState(data::BitVector) = new(data, 1)
end
data(state::ParseState) = @view state.data[state.offset:end]
isfinish(state::ParseState) = state |> data |> isempty
update!(state::ParseState, parsed::Int) = state.offset += parsed
align!(state::ParseState) = update!(state,5 - (state.offset % 4))
show(state::ParseState) = println(state |> data .|> Int |> join)

function hex2binvector(packet::String)
    bitdigits = packet |> collect .|> c -> parse(Int, c; base=16) |> z-> bitstring(z)[end-3:end]
    BitVector(join(bitdigits) |> collect .|> c -> parse(Int, c; base=2))
end
parseint(packet, size::Int) = foldl((x,y)->2 * x + y, @view packet[1:size])

function parseNbits!(state::ParseState, nbits::Int) 
    value = foldl((x,y)->2 * x + y, @view data(state)[1:nbits])
    update!(state, nbits)
    value
end

function parseliteralvalue!(state::ParseState, version::Int)
    value = 0
    for (n,chunk) in enumerate(Iterators.partition(data(state), 5))
        value = foldl((x,y)->2*x+y, (@view chunk[2:end]);init=value)
        if chunk[1] == 0
            update!(state, n*5)
            return Literal(version, value)
        end
    end
end

function parseoperatorl0!(state::ParseState, version::Int, opcode::Int)
    subsizebits = parseNbits!(state, 15)
    substate = ParseState(data(state)[1:subsizebits])
    childs = Expression[]
    while !isfinish(substate)
        push!(childs, parsepacket!(substate))
    end
    update!(state, subsizebits)
    Operator(version, opcode, childs)
end

function parseoperatorl1!(state::ParseState, version::Int, opcode::Int)
    nchilds = parseNbits!(state, 11)
    childs = Expression[]
    for _ in 1:nchilds
        push!(childs, parsepacket!(state))
    end
    Operator(version, opcode, childs)
end


function parsepacket!(state::ParseState)
    version = parseNbits!(state, 3)
    typeid = parseNbits!(state, 3)
    if typeid == LITERAL
        return parseliteralvalue!(state, version)
    else
        if parseNbits!(state, 1) == 0
            return parseoperatorl0!(state, version, typeid)
        else
            return parseoperatorl1!(state, version, typeid)
        end
    end
end

parseinput(input::String) = input |> hex2binvector |> ParseState |> parsepacket!

function main1()
    readline("day_16.txt") |> parseinput |> sumversions
end

function main2()
    readline("day_16.txt") |> parseinput |> value
end

println(main1())
println(main2())