using DataStructures
include("common.jl")

function increment(map::AbstractMatrix{Int}, value::Int)
    result = map .+ value
    result[result .>= 10] .-= 9
    result
end

function enlargemap(map::AbstractMatrix{Int})
    firstrow = hcat([increment(map, i) for i in 0:4]...)
    result = vcat([increment(firstrow,i) for i in 0:4]...)
    result
end

function rundijkstra(map::AbstractMatrix{Int})
    unvisited = Set{CartesianIndex{2}}(CartesianIndices(map))
    pq = PriorityQueue{CartesianIndex{2}, Int}()
    start = CartesianIndex((1,1))
    final = CartesianIndex(size(map))
    neigbours = safeNeighbours4(map)
    result = fill(sum(map), size(map))
    result[start] = 0
    pq[start] = 0
    while final ∈ unvisited
        currentidx = dequeue!(pq)
        for neighbour in neigbours(currentidx)
            if neighbour ∈ unvisited
                distviacurrent = result[currentidx] + map[neighbour]
                if distviacurrent < result[neighbour]
                    result[neighbour] = distviacurrent
                    pq[neighbour] = distviacurrent
                end
            end
        end
        setdiff!(unvisited, [currentidx])
    end
    result[final]
end
function main1()
    readMap("day_15.txt") |> rundijkstra
end

function main2()
    readMap("day_15.txt") |> enlargemap |> rundijkstra
end

main1()
main2()