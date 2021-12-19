abstract type Node end
mutable struct Pair <: Node
    parent::Union{Pair, Nothing}
    left::Union{Node, Nothing}
    right::Union{Node, Nothing}
    Pair(parent::Union{Pair, Nothing}) = new(parent, nothing, nothing) 
end

mutable struct Leaf <: Node
    parent::Pair
    value::Int
end

build(item::Int, parent::Union{Pair, Nothing}=nothing) = Leaf(parent, item)

show(pair::Pair) = "[$(show(pair.left)), $(show(pair.right))]"
show(leaf::Leaf) = "$(leaf.value)"
show(nothing::Nothing) = "nothing"

weights = [3,2]'
magnitude(pair::Pair) = weights * [magnitude(pair.left), magnitude(pair.right)]
magnitude(leaf::Leaf) = leaf.value

function build(item::Vector, parent::Union{Pair, Nothing}=nothing)
    result = Pair(parent)
    result.left= build(item[1], result) 
    result.right = build(item[2], result)
    result
end

isroot(node::Pair) = isnothing(node.parent)
isterminal(pair::Pair) = (pair.left isa Leaf) && (pair.right isa Leaf)
level(node::Node) = isroot(node) ? 0 : 1+level(node.parent)
function Base.:+(left::Pair, right::Pair)
    root = Pair(nothing)
    
    root.left = deepcopy(left) 
    root.left.parent = root
    
    root.right = deepcopy(right)
    root.right.parent = root
    root
end

function updatesibling!(sibling::Union{Leaf, Nothing}, inc::Int)
    if !isnothing(sibling)
        sibling.value += inc
    end
end

function updateparent!(parent::Pair, oldchild::Node, newchild::Node)
    if parent.left == oldchild
        parent.left = newchild
    else
        parent.right = newchild
    end
end

needexplode(pair::Pair) = level(pair) >= 4

function sibling(pair::Pair, testfunc::Function, childfunc1::Function, childfuncs::Function)
    current = pair
    while !isnothing(current.parent) && testfunc(current)
        current = current.parent
    end
    if isnothing(current.parent)
        return nothing
    end

    current = childfunc1(current.parent)
    while !(current isa Leaf)
        current = childfuncs(current)
    end
    current
end
leftsibling(pair::Pair) = sibling(pair, n->n == n.parent.left, n->n.left, n->n.right)
rightsibling(pair::Pair) = sibling(pair, n->n == n.parent.right, n->n.right, n->n.left)

function explode!(pair::Pair)
    updatesibling!(leftsibling(pair), pair.left.value)
    updatesibling!(rightsibling(pair), pair.right.value)
    updateparent!(pair.parent, pair, Leaf(pair.parent, 0))
end

needsplit(leaf::Leaf) = leaf.value >= 10

function split!(leaf::Leaf)
    vleft, vright = isodd(leaf.value) ? (leaf.value ÷ 2, leaf.value ÷ 2 + 1) : (leaf.value ÷ 2, leaf.value ÷ 2)
    nextleaf = Pair(leaf.parent)
    nextleaf.left = Leaf(nextleaf, vleft)
    nextleaf.right = Leaf(nextleaf, vright)
    updateparent!(leaf.parent, leaf, nextleaf)
end

pairtraverse(pair::Pair) = isterminal(pair) ? [pair] : [pairtraverse(pair.left);pairtraverse(pair.right)]
pairtraverse(leaf::Leaf) = []
leaftraverse(pair::Pair) = isterminal(pair) ? [pair.left, pair.right] : [leaftraverse(pair.left);leaftraverse(pair.right)]
leaftraverse(leaf::Leaf) = [leaf]

function explodereduce!(root::Node)
    for pair in pairtraverse(root)
        if needexplode(pair)
            explode!(pair)
            return true
        end
    end
    return false
end

function splitreduce!(root::Node)
    for leaf in leaftraverse(root)
        if needsplit(leaf)
            split!(leaf)
            return true
        end
    end
    return false
end

function fullreduce!(root::Node)
    while explodereduce!(root) || splitreduce!(root)
    end
    root
end

function main1()
    numbers = readlines("day_18.txt") .|> Meta.parse .|> eval .|> build
    result = foldl((f,r) -> fullreduce!(f+r), numbers[2:end];init=numbers[1])
    show(result) |> println
    magnitude(result)
end

function main2()
    numbers = readlines("day_18.txt") .|> Meta.parse .|> eval .|> build
    apply(n1,n2) = magnitude(fullreduce!(n1 + n2))
    maximum(apply(x,y) for (x,y) in Iterators.product(numbers, numbers) if x!= y)
end