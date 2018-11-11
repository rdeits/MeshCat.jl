module SceneTrees

export SceneNode, Path

struct Path <: AbstractVector{String}
    entries::Vector{String}
end

Base.size(p::Path) = size(p.entries)
Base.IndexStyle(::Type{Path}) = IndexLinear()
Base.convert(::Type{Path}, x::AbstractVector{<:AbstractString}) = Path(x)

Base.joinpath(p::Path, s...) = foldl(joinpath, s, init=p)
Base.joinpath(p::Path, s::Symbol) = joinpath(p, String(s))
Base.joinpath(p::Path, s::AbstractString) = _joinpath(p, split(s, '/'))

_joinpath(p::Path, s::AbstractVector{<:AbstractString}) = foldl(_joinpath, s, init=p)
_joinpath(p::Path, s::AbstractString) = isempty(s) ? Path(String[]) : Path(vcat(p.entries, s))

Base.show(io::IO, p::Path) = print(io, string('/', join(p.entries, '/')))
Base.getindex(p::Path, i::Int) = p.entries[i]
Base.getindex(p::Path, v::AbstractVector) = Path(p.entries[v])
Base.setindex(p::Path, x, i::Int) = p.entries[i] = x

mutable struct SceneNode
    object::Union{Vector{UInt8}, Nothing}
    transform::Union{Vector{UInt8}, Nothing}
    children::Dict{String, SceneNode}
end

SceneNode() = SceneNode(nothing, nothing, Dict{String, SceneNode}())

Base.getindex(s::SceneNode, name::AbstractString) = get!(SceneNode, s.children, name)
function Base.delete!(s::SceneNode, name::AbstractString)
    if haskey(s.children, name)
        delete!(s.children, name)
    end
end

function Base.getindex(s::SceneNode, path::Path)
    if length(path.entries) == 0
        return s
    else
        return s[path[1]][path[2:end]]
    end
end

function Base.delete!(s::SceneNode, path::Path)
    parent = s[path[1:end-1]]
    child = path[end]
    delete!(parent, child)
end

function Base.foreach(f::Function, s::SceneNode)
    f(s)
    for (k, v) in s.children
        foreach(f, v)
    end
end

end


