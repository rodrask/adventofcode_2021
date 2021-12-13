Vertex = AbstractString
isbig(v::Vertex) = isuppercase(v[1])

isstart(v::Vertex) = v=="start"
isend(v::Vertex) = v=="end"

struct Graph
    adjacencies::Dict{Vertex,Vector{Vertex}}
    function Graph(path::String)
        adj = Dict{Vertex,Vector{Vertex}}()
        for line in eachline(path)
            v1, v2 = split(line, "-")
            if !(isend(v1) || isstart(v2)) # edge v1 -> v2
                push!(get!(adj, v1, Vertex[]), v2)
            end
            if !(isstart(v1) || isend(v2)) # edge v2 -> v1
                push!(get!(adj, v2, Vertex[]), v1)
            end
        end
        new(adj)
    end
end

neighbours(g::Graph, v::Vertex) = get(g.adjacencies, v, Vertex[])

struct PathPoint
    v::Vertex
    parent::Union{PathPoint,Nothing}
    visited::Set{Vertex}
    doubleVisit::Bool
end

PathPoint(v::Vertex) = PathPoint(v, nothing, Set([v]), false)
function PathPoint(parent::PathPoint, v::Vertex) 
    if isbig(v)
        PathPoint(v, parent, parent.visited, parent.doubleVisit)
    else
        PathPoint(v, parent, union(parent.visited, [v]), parent.doubleVisit || v ∈ parent.visited)
    end
end

function unrollPath(endPoint::PathPoint)
    result = Vertex[]
    while !isnothing(endPoint.parent)
        pushfirst!(result, endPoint.v)
        endPoint = endPoint.parent
    end
    pushfirst!(result, endPoint.v)
    result
end

function countPaths(g::Graph, testFunction::Function)
    nPaths = 0
    frontPoints = PathPoint[PathPoint("start")]
    while !isempty(frontPoints)
        currentPoint = pop!(frontPoints)
        for adjVertex in neighbours(g, currentPoint.v)
            if isend(adjVertex)
                nPaths += 1
            elseif testFunction(adjVertex, currentPoint)
                push!(frontPoints, PathPoint(currentPoint, adjVertex))
            end
        end
    end
    nPaths
end

function main1()
    testFunction(adjVertex::Vertex, currentPoint::PathPoint) =  isbig(adjVertex) || adjVertex ∉ currentPoint.visited
    graph = Graph("day_12.txt")
    countPaths(graph, testFunction)
end

function main2()
    testFunction(adjVertex::Vertex, currentPoint::PathPoint) =  !currentPoint.doubleVisit || isbig(adjVertex) || adjVertex ∉ currentPoint.visited
    graph = Graph("day_12.txt")
    countPaths(graph, testFunction)
end

println(main1())
println(main2())