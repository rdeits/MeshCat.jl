const GeometryLike = Union{AbstractGeometry, AbstractMesh, MeshFileGeometry}

"""
Represents a three.js Object, consisting of a geometry and a material.
"""
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
Object(g::GeometryLike) = MeshObject(g)
Object(g::GeometryLike, m::AbstractMaterial) = MeshObject(g, m)
Object(c::PointCloud) = Points(c)
Object(c::PointCloud, m::AbstractMaterial) = Points(c, m)
Object(t::Triad) = LineSegments(t, LineBasicMaterial(vertexColors=2))

@deprecate Mesh(args...) MeshObject(args...)

MeshObject(g, m) = Object(g, m, "Mesh")
MeshObject(geometry::GeometryLike) = MeshObject(geometry, defaultmaterial())

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
    linewidth::Float64 = 1.  # NOTE: linewidth does not work in modern browsers for LineBasicMaterial. Use FatLineMaterial instead for configurable line widths.
    vertexColors::Int = 0    # TODO: make an enum
    side::Int = 2            # TODO: make an enum https://github.com/mrdoob/three.js/blob/d55897b8e9b2632896d8ac146a05b3b4be3668f8/src/constants.js#L14
    wireframe::Bool = false
    wireframeLinewidth::Float64 = 1
end

threejs_type(m::GenericMaterial) = m._type

MeshBasicMaterial(;kw...) = GenericMaterial(_type="MeshBasicMaterial"; kw...)
MeshLambertMaterial(;kw...) = GenericMaterial(_type="MeshLambertMaterial"; kw...)
MeshPhongMaterial(;kw...) = GenericMaterial(_type="MeshPhongMaterial"; kw...)
LineBasicMaterial(;kw...) = GenericMaterial(_type="LineBasicMaterial"; kw...)

@with_kw struct PointsMaterial <: AbstractMaterial
    color::RGBA{Float32}=RGB(1., 1., 1.)
    size::Float32 = 0.002
    vertexColors::Int = 0
end

"""
    FatLineMaterial(; kwargs...)

Material for rendering lines with configurable width using Three.js Line2.

Unlike `LineBasicMaterial`, the `linewidth` parameter in `FatLineMaterial` actually works
in modern browsers. This is achieved by rendering lines as actual geometry (meshes) instead
of GL lines.

# Keyword Arguments
- `color::RGBA{Float32} = RGB(1., 1., 1.)`: Line color
- `linewidth::Float64 = 1.0`: Line width (in pixels if worldUnits=false, or world units if worldUnits=true)
- `vertexColors::Bool = false`: Use per-vertex colors from geometry
- `dashed::Bool = false`: Enable dashed line rendering
- `dashScale::Float64 = 1.0`: Scale of dashes (only used if dashed=true)
- `dashSize::Float64 = 1.0`: Length of dashes (only used if dashed=true)
- `gapSize::Float64 = 1.0`: Length of gaps between dashes (only used if dashed=true)
- `worldUnits::Bool = false`: If false (default), linewidth is in screen pixels. If true, linewidth is in world units and scales with zoom

# Example
```julia
using MeshCat
using GeometryBasics
using Colors

vis = Visualizer()
points = [Point(0, 0, 0), Point(1, 0, 0), Point(1, 1, 0)]
material = FatLineMaterial(color=RGB(1, 0, 0), linewidth=5.0)
setobject!(vis[:line], FatLine(points, material))
```

See also: [`FatLineGeometry`](@ref), [`FatLine`](@ref)
"""
@with_kw struct FatLineMaterial <: AbstractMaterial
    color::RGBA{Float32} = RGB(1., 1., 1.)
    linewidth::Float64 = 1.0
    vertexColors::Bool = false
    dashed::Bool = false
    dashScale::Float64 = 1.0
    dashSize::Float64 = 1.0
    gapSize::Float64 = 1.0
    worldUnits::Bool = false
end

"""
    FatLine(geometry::FatLineGeometry, material::FatLineMaterial=FatLineMaterial())
    FatLine(points::AbstractVector{<:Point}, material::FatLineMaterial=FatLineMaterial())

Create a Line2 object with configurable line width that works in modern browsers.

# Arguments
- `geometry`: FatLineGeometry containing line points and optional colors
- `points`: Vector of 3D points (convenience constructor that creates FatLineGeometry)
- `material`: FatLineMaterial specifying appearance (linewidth, color, etc.)

See also: [`FatLineGeometry`](@ref), [`FatLineMaterial`](@ref)
"""
FatLine(g::FatLineGeometry, m::FatLineMaterial=FatLineMaterial()) = Object(g, m, "Line2")
FatLine(points::AbstractVector{<:Point}, m::FatLineMaterial=FatLineMaterial()) = FatLine(FatLineGeometry(points), m)

