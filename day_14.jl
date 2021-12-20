include("common.jl")

productregex = r"(?<f1>[A-Z]{1})(?<f2>[A-Z]{1}) -> (?<t>[A-Z]{1})"

function parseline(line::AbstractString)
    m = match(productregex, line)
    (m[:f1][1], m[:f2][1]) => m[:t][1]
end

loadProductionRules(io::IOStream) = eachline(io) .|> parseline |> Dict

function applyRulesAndScore(template::AbstractVector{Char}, rules::Dict{Tuple{Char,Char}, Char}, steps::Int)
    paircounter = Dict{Tuple{Char, Char}, Int}()
    counter = Dict{Char, Int}()
    foreach(ch -> increment!(counter,ch), template)
    foreach(pair -> increment!(paircounter,pair), zip(template, template[2:end]))
    for _ in 1:steps
        nextpaircounter = Dict{Tuple{Char, Char}, Int}()
        for ((p1,p2), c) in pairs(paircounter)
            newchar = rules[(p1,p2)]
            increment!(counter, newchar, c)
            increment!(nextpaircounter, (p1,newchar), c)
            increment!(nextpaircounter, (newchar,p2), c)
        end
        paircounter = nextpaircounter
    end
    (counter |> findmax |> first) - (counter |> findmin |> first)
end

function readInput(path)
    open(path) do io
        template = readline(io) |> collect
        readline(io)
        template, loadProductionRules(io)
    end
end


function main1()
    template, rules = readInput("day_14_test.txt")
    println(applyRulesAndScore(template, rules, 10))
end

function main2()
    template, rules = readInput("day_14.txt")
    println(applyRulesAndScore(template, rules, 40))
end

main1()
main2()
