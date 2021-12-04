using DelimitedFiles
CARD_SIZE = 5

struct BingoCard
    lines::AbstractVector{Set{Int}}
    field::AbstractMatrix{Int}
    function BingoCard(field::AbstractMatrix{Int})
        lines = collect(Set(line) for line in Iterators.flatten((eachcol(field), eachrow(field))))
        new(lines, field)
    end
end

parseDraw(l::String) = split(l, ",") .|> c -> parse(Int, c)

function parseBoard(file, N_lines=CARD_SIZE)
    vectors = []
    for _ in 1:N_lines
        row = readline(file) |> strip |> l -> split(l, " ", keepempty=false) .|> c -> parse(Int, c)
        push!(vectors, row)
    end
    hcat(vectors...)'
end

testCard(card::BingoCard, draw::AbstractVector{Int}) = !isnothing(findfirst(l -> l ⊆ draw, card.lines))

winnerScore(card::BingoCard, draw::AbstractVector{Int}) = sum((v for v in card.field if v ∉ draw)) * draw[end]

function readInput(filename)
    draw::Vector{Int} = []
    cards::Vector{BingoCard} = []
    open(filename) do io
        append!(draw, parseDraw(readline(io)))
        while !eof(io)
            readline(io)
            card = parseBoard(io) |> BingoCard
            push!(cards, card)
        end
    end
    return draw, cards
end

function firstWinner(draw::AbstractVector{Int}, cards::AbstractVector{BingoCard})
    for p in CARD_SIZE:length(draw)
        p_draw = @view draw[1:p]
        winner = findfirst(card -> testCard(card, p_draw), cards)
        if !isnothing(winner)
            return cards[winner], p_draw
            break
        end
    end
end

function lastWinner(draw::AbstractVector{Int}, cards::AbstractVector{BingoCard})
    players = Set(cards)
    for p in CARD_SIZE:length(draw)
        p_draw = @view draw[1:p]
        p_winners = filter(c -> testCard(c, p_draw), players)
        setdiff!(players, p_winners)
        if length(players) == 0
            return first(p_winners), p_draw
        end
    end
end


function main1()
    draw, cards = readInput("day_4.txt")
    winner, win_draw = firstWinner(draw, cards)
    println("Draw: $(win_draw)")
    println("First winner:")
    writedlm(stdout, winner.field)
    println("Winner score: $(winnerScore(winner, win_draw))")
end

function main2()
    draw, cards = readInput("day_4.txt")
    winner, win_draw = lastWinner(draw, cards)
    println("Draw: $(win_draw)")
    println("Last winner:")
    writedlm(stdout, winner.field)
    println("Winner score: $(winnerScore(winner, win_draw))")
end


main1()
main2()