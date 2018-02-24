module SceneTrees

export SceneNode

mutable struct SceneNode
    object::Nullable{Vector{UInt8}}
    transform::Nullable{Vector{UInt8}}
    children::Dict{String, SceneNode}
end

SceneNode() = SceneNode(nothing, nothing, Dict{String, SceneNode}())

Base.getindex(s::SceneNode, name::AbstractString) = get!(SceneNode, s.children, name)
function Base.delete!(s::SceneNode, name::AbstractString)
    if haskey(s.children, name)
        delete!(s.children, name)
    end
end

function Base.getindex(s::SceneNode, path::AbstractVector{<:AbstractString})
    if length(path) == 0
        return s
    else
        return s[first(path)][path[2:end]]
    end
end

function Base.delete!(s::SceneNode, path::AbstractVector{<:AbstractString})
    parent = s[path[1:end-1]]
    chlid = path[end]
    delete!(parent, child)
end

function Base.foreach(f::Function, s::SceneNode)
    f(s)
    for (k, v) in s.children
        foreach(f, v)
    end
end

end


