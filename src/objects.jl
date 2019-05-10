const GeometryLike = Union{AbstractGeometry, AbstractMesh, MeshFileGeometry}
abstract type AbstractObject end
abstract type AbstractMaterial end

struct Object{G <: GeometryLike, M <: AbstractMaterial} <: AbstractObject
    geometry::G
    material::M
    _type::String
end

geometry(o::Object) = o.geometry
material(o::Object) = o.material
threejs_type(o::Object) = o._type

defaultmaterial(args...; kw...) = MeshLambertMaterial(args...; kw...)

# Default object types for geometries, point clouds, and triads
Object(g::GeometryLike) = Mesh(g)
Object(g::GeometryLike, m::AbstractMaterial) = Mesh(g, m)
Object(c::PointCloud) = Points(c)
Object(c::PointCloud, m::AbstractMaterial) = Points(c, m)
Object(t::Triad) = LineSegments(t, LineBasicMaterial(vertexColors=2))

Mesh(g, m) = Object(g, m, "Mesh")
Mesh(geometry::GeometryLike) = Mesh(geometry, defaultmaterial())

function Mesh(g::HomogenousMesh)
    if g.color == nothing
        Mesh(g, defaultmaterial())
    else
        Mesh(g, defaultmaterial(color=g.color))
    end
end

Points(g, m) = Object(g, m, "Points")
Points(geometry::GeometryLike; kw...) = Points(geometry, PointsMaterial(kw...))

for line_type in [:LineSegments, :Line, :LineLoop]
    @eval $line_type(g::AbstractGeometry, m::AbstractMaterial=LineBasicMaterial()) = Object(g, m, $(string(line_type)))
    @eval $line_type(points::AbstractVector{<:Point}, m::AbstractMaterial=LineBasicMaterial()) = $line_type(PointCloud(points), m)
end

struct PngImage
    data::Vector{UInt8}
end

PngImage(fname::AbstractString) = PngImage(open(read, fname))

@with_kw struct Texture
    image::PngImage
    wrap::Tuple{Int, Int} = (1001, 1001)  # TODO: replace with enum
    repeat::Tuple{Int, Int} = (1, 1)      # TODO: what does this mean?
end

@with_kw mutable struct GenericMaterial <: AbstractMaterial
    _type::String
    color::RGBA{Float32} = RGB(1., 1., 1.)
    map::Union{Texture, Nothing} = nothing
    depthFunc::Int = 3
    depthTest::Bool = true
    depthWrite::Bool = true
    linewidth::Float64 = 1.
    vertexColors::Int = 0    # TODO: make an enum
    side::Int = 2            # TODO: make an enum https://github.com/mrdoob/three.js/blob/d55897b8e9b2632896d8ac146a05b3b4be3668f8/src/constants.js#L14
end

threejs_type(m::GenericMaterial) = m._type

MeshBasicMaterial(;kw...) = GenericMaterial(_type="MeshBasicMaterial"; kw...)
MeshLambertMaterial(;kw...) = GenericMaterial(_type="MeshLambertMaterial"; kw...)
MeshPhongMaterial(;kw...) = GenericMaterial(_type="MeshPhongMaterial"; kw...)
LineBasicMaterial(;kw...) = GenericMaterial(_type="LineBasicMaterial"; kw...)

@with_kw struct PointsMaterial <: AbstractMaterial
    color::RGBA{Float32}=RGB(1., 1., 1.)
    size::Float32 = 0.002
    vertexColors::Int = 2
end
