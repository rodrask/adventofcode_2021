struct Scanner
    id::Int
    beacons::AbstractMatrix{Int}
 end
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