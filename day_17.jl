
targetregex = r"^target area: x=(?<x1>\d+)\.\.(?<x2>\d+), y=(?<y1>\-?\d+)\.\.(?<y2>\-?\d+)"
function readtargetarea(line::String)
    m = match(targetregex, line)
    p(x) = parse(Int, x)
    Target(p(m[:x1]), p(m[:x2]), p(m[:y1]), p(m[:y2]))
end

const X = 1
const Y = 2
const Vx = 3
const Vy = 4

struct Target
    xmin::Int
    xmax::Int
    ymin::Int
    ymax::Int
end

Base.in(pos::Vector{Int}, t::Target) = (t.xmin <= pos[X] <= t.xmax) && (t.ymin <= pos[Y] <= t.ymax)
missed(pos::Vector{Int}, t::Target) = (pos[Vx]>=0 && pos[X] > t.xmax) || (pos[X]+pos[Vx] > t.xmax) || 
                                      (pos[Vx]<=0 && pos[X] < t.xmin) ||
                                      (pos[Vy]<=0 && pos[Y] < t.ymin) || (pos[Y]+pos[Vy] < t.ymin)

init(vx::Int, vy::Int) = [0, 0, vx, vy] 
dv = [0,0,-1,-1]
movemat = [1 0 1 0;
           0 1 0 1;
           0 0 1 0;
           0 0 0 1]

function step(pos::Vector{Int})
    result = movemat * pos + dv
    result[3] = max(0, result[3])
    result
end

function probe(pos::Vector{Int}, target::Target)
    while true
        pos = step(pos)
        if pos ∈ target
            return true
        end
        if missed(pos, target)
            return false
        end
    end
    result
end

maxx(vx::Int) = (abs(vx) * (1+abs(vx)) ÷ 2)*sign(vx)
function findminvx(t::Target)
    for i in 1:t.xmin
        if maxx(i) >= t.xmin
            return i
        end
    end
end

function canhit(vy::Int, target::Target, minvx::Int)
    for vx in 1:target.xmax
        if probe(init(vx, vy), target)
            return true
        end
    end
    return false
end

maxheight(vy::Int) = vy > 0 ? vy * (vy+1) ÷ 2 : 0

function main2()
    target = readtargetarea(readline("day_17.txt"))
    minvx = findminvx(target)
    vy = 1000
    while !canhit(vy, target, minvx)
        vy -= 1
    end
    maxheight(vy)
end

function main2()
    target = readtargetarea(readline("day_17.txt"))
    minvx = findminvx(target)
    counter = 0
    for vx in minvx:target.xmax
        for vy in 1000:-1:target.ymin
            counter += Int(probe(init(vx,vy), target))
        end
    end
    counter
end

println(main1())
println(main2())