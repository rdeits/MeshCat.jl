abstract type AbstractCommand end

struct Path
    entries::Vector{String}
end

Base.convert(::Type{Path}, x::AbstractVector{<:AbstractString}) = Path(x)
Base.vcat(p::Path, s...) = Path(vcat(p.entries, s...))
Base.show(io::IO, p::Path) = print(io, string('/', join(p.entries, '/')))

struct SetObject{O <: AbstractObject} <: AbstractCommand
    object::O
    path::Path
end

struct SetTransform{T <: Transformation} <: AbstractCommand
    tform::T
    path::Path
end

struct Delete <: AbstractCommand
    path::Path
end
