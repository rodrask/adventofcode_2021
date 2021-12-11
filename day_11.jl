include("common.jl")

const FLASH = 10
const f = CartesianIndex(1,1)

neighbours(idx::CartesianIndex{2}, l::CartesianIndex{2}) = [i for i in max(f, idx-f):min(l, idx+f) if i!=idx]
neighboursFunction(m::AbstractMatrix) = myneighbours(idx::CartesianIndex{2}) = neighbours(idx, CartesianIndex(size(m)))

function step(octomap::Matrix{Int}, myneighbours::Function)
    result = octomap .+ 1
    flashes = Set{CartesianIndex{2}}()
    flashstack = [idx for idx in CartesianIndices(octomap) if result[idx] == FLASH]
    while !isempty(flashstack)
        flashidx = pop!(flashstack)
        push!(flashes, flashidx)
        flashneighbours = myneighbours(flashidx)
        for nidx in flashneighbours
            nvalue = result[nidx] += 1
            if nvalue == FLASH && nvalue ∉ flashes
                push!(flashes, nidx)
                push!(flashstack, nidx)
            end
        end
    end
    result[collect(flashes)] .= 0
    result, length(flashes)
end

function main1()
    octomap = readMap("day_11.txt")
    myneighbours = neighboursFunction(octomap)
    total = 0
    for _ in 1:100
        octomap, nflashes = step(octomap, myneighbours)
        total += nflashes
    end
    println("Total $total flashes")
end

function main2()
    octomap = readMap("day_11.txt")
    mapsize = prod(size(octomap))
    myneighbours = neighboursFunction(octomap)
    nstep = nflashes = 0
    while nflashes != mapsize
        nstep += 1
        octomap, nflashes = step(octomap, myneighbours)
    end
    println("Synchronize at step $nstep")
end

main1()
main2()