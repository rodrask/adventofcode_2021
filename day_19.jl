include("common.jl")
using LinearAlgebra, Combinatorics
mutable struct Scanner
    id::Int
    beacons::AbstractMatrix{Int}
 end
eachbeacon(s::Scanner) = eachcol(s.beacons)

scannerregex = r"--- scanner (?<id>\d+) ---"

function readscanner(io)
    line = readline(io)
    m = match(scannerregex, line)
    scannerid = parse(Int, m[:id])
    beacons = Vector[]
    line = readline(io)
    while !isempty(line)
        coords = split(line,",") .|> c -> parse(Int, c)
        push!(beacons, coords)
        line = readline(io)
    end
    Scanner(scannerid, hcat(beacons...))
end

function readinput(path)
    scanners = Scanner[]
    open(path) do io
        while !eof(io)
            push!(scanners, readscanner(io))
        end
    end
    scanners
end

const flips = [diagm([flip...]) for flip in Iterators.product([-1,1], [-1,1], [-1,1])]
const transforms = [f[p,:] for (f,p) in Iterators.product(flips, permutations(1:3)) if det(f[p,:]) > 0]

addbeacons!(s1::Scanner, s2::Scanner, transform::Matrix{Int}, shift::Vector{Int}) = 
    s1.beacons = hcat(union(eachcol(s1.beacons), eachcol((transform * s2.beacons) .+ shift))...)

manhdist(s1::AbstractVector{Int}, s2::AbstractVector{Int}) = s1-s2 .|> abs |> sum

function testpair(s1::Scanner, s2::Scanner, minreq::Int=12)
    for t in transforms
        diffcounter = Dict{Vector, Int}()
        transformed = t * s2.beacons
        for (b1, b2) in Iterators.product(eachbeacon(s1), eachcol(transformed))
            diff = b1 - b2
            increment!(diffcounter, diff)
        end
        (maxmatch, diff) = findmax(diffcounter)
        if maxmatch >= minreq
            return t, diff
        end
    end
    return nothing
end

function buildmap(scanners::Vector{Scanner})
    mainscanner = scanners[1]
    rest = Set(scanners[2:end])
    scannerscoords = zeros(Int, (3, length(scanners)))
    while !isempty(rest)
        for current in rest
            result = testpair(mainscanner, current)
            if !isnothing(result)
                transform, shift = result
                addbeacons!(mainscanner, current, transform, shift)
                delete!(rest, current)
                scannerscoords[:,current.id+1] .= shift
            end
        end
    end
    mainscanner, scannerscoords
end

function main12()
    scanners = readinput("day_19.txt")
    mainscanner, scannerscoords = buildmap(scanners)
    maxdist = maximum(manhdist(s1,s2) for (s1,s2) in Iterators.product(eachcol(scannerscoords), eachcol(scannerscoords)))
    println("Total beacons ",size(mainscanner.beacons, 2))
    println("Max distance ",maxdist)
end

main12()
