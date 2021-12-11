include("common.jl")

const FLASH = 10
const f = CartesianIndex(1,1)

neighbours(idx::CartesianIndex{2}, l::CartesianIndex{2}) = [i for i in max(f, idx-f):min(l, idx+f) if i!=idx]
neighboursFunction(m::AbstractMatrix) = myneighbours(idx::CartesianIndex{2}) = neighbours(idx, CartesianIndex(size(m)))

function step!(octomap::Matrix{Int}, myneighbours::Function)
    octomap .+=  1
    flashes = Set{CartesianIndex{2}}()
    flashstack = [idx for idx in CartesianIndices(octomap) if octomap[idx] == FLASH]
    while !isempty(flashstack)
        flashidx = pop!(flashstack)
        push!(flashes, flashidx)
        flashneighbours = myneighbours(flashidx)
        for nidx in flashneighbours
            nvalue = octomap[nidx] += 1
            if nvalue == FLASH && nvalue ∉ flashes
                push!(flashes, nidx)
                push!(flashstack, nidx)
            end
        end
    end
    octomap[collect(flashes)] .= 0
    length(flashes)
end

function main1()
    octomap = readMap("day_11.txt")
    myneighbours = neighboursFunction(octomap)
    total = sum((step!(octomap, myneighbours) for _ in 1:100))
    println("Total $total flashes")
end

function main2()
    octomap = readMap("day_11.txt")
    mapsize = prod(size(octomap))
    myneighbours = neighboursFunction(octomap)
    nstep = 1
    while step!(octomap, myneighbours) != mapsize
        nstep += 1
    end
    println("Synchronize at step $nstep")
end

main1()
main2()