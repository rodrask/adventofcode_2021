productregex = r"(?<f1>[A-Z]{1})(?<f2>[A-Z]{1}) -> (?<t>[A-Z]{1})"

function parseline(line::AbstractString)
    m = match(productregex, line)
    (m[:f1][1], m[:f2][1]) => m[:t][1]
end

loadProductionRules(io::IOStream) = eachline(io) .|> parseline |> Dict

function applyRules(template::AbstractVector{Char}, rules::Dict{Tuple{Char,Char}, Char})
    result = flatten((f1, rules[(f1,f2)]) for (f1,f2) in zip(template, template[2:end]))
    append!(result, [template[end]])
    result
end

function score(template::Vector{Char})
    counter = Dict{Char, Int}()
    foreach(ch -> counter[ch] = 1 + get(counter, ch, 0), template)
    counter |> findmax |> first - counter |> findmin |> first
end

steps = 10
function main1() 
    template, rules = open("day_14_test.txt") do io
        template = readline(io) |> collect
        readline(io)
        template, loadProductionRules(io)
    end
    template = foldl((t, _)-> applyRules(t, rules), 1:steps;init=template)
    score(template)
end

main1()