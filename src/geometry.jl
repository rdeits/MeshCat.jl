"""
N-dimensional ellipsoid. Note that only N=3 dimensional ellipsoids can be rendered
in the visualizer.
"""
struct HyperEllipsoid{N, T} <: GeometryPrimitive{N, T}
    center::Point{N, T}
    radii::Vec{N, T}
end

GeometryBasics.origin(geometry::HyperEllipsoid{N, T}) where {N, T} = geometry.center
radii(geometry::HyperEllipsoid{N, T}) where {N, T} = geometry.radii

"""
A collection of points which will be rendered as a point cloud in the visualiezr.

You can set the color of each point indepenedntly when you construct a PointCloud,
or you can set the overall point color by passing a `PointsMaterial` as the material
when you call `setobject!(vis, point_cloud, material)`
"""
struct PointCloud{T, PointType <: StaticVector{3, T}, C <: Colorant} <: AbstractGeometry{3, T}
    position::Vector{PointType}
    color::Vector{C}
end

function PointCloud(position::AbstractVector{<:AbstractVector{T}},
           color::AbstractVector{C}=RGB{Float32}[]) where {T, C <: Colorant}
    PointCloud{T, Point{3, T}, C}(position, color)
end

"""
A visual representation of the origin of a coordinate system, drawn as three
lines in red, green, and blue along the x, y, and z axes. The `scale` parameter
controls the length of the three lines.
"""
struct Triad <: AbstractGeometry{3, Float64}
    scale::Float64

    Triad(scale=1.0) = new(scale)
end

"""
A 3D cone, represented by the position of the origin of its base, the position of its tip,
and the radius of its base.
"""
struct Cone{N, T} <: AbstractGeometry{N, T}
    origin::Point{N, T}
    apex::Point{N, T}
    r::T
end

GeometryBasics.origin(geometry::Cone) = geometry.origin

"""
    FatLineGeometry(position::AbstractVector{<:AbstractVector}, color::AbstractVector{<:Colorant}=RGB{Float32}[])

Geometry for rendering lines with arbitrary width using Three.js Line2.

This geometry type uses actual mesh geometry instead of GL lines, which allows for
configurable line width that works across all modern browsers (unlike the deprecated
GL_LINEWIDTH parameter).

# Arguments
- `position`: Vector of 3D points defining the line path
- `color`: Optional vector of colors for per-vertex coloring (must be same length as position if provided)

# Example
```julia
using MeshCat
using GeometryBasics
using Colors

vis = Visualizer()

# Simple line
points = [Point(0, 0, 0), Point(1, 0, 0), Point(1, 1, 0)]
setobject!(vis[:simple], FatLine(points, FatLineMaterial(linewidth=3.0)))

# Line with vertex colors
points = [Point(0, 0, i*0.1) for i in 0:10]
colors = [RGB(i/10, 0, 1-i/10) for i in 0:10]
setobject!(vis[:colored], FatLine(FatLineGeometry(points, colors),
                                   FatLineMaterial(linewidth=5.0, vertexColors=true)))
```

See also: [`FatLineMaterial`](@ref), [`FatLine`](@ref)
"""
struct FatLineGeometry{T, PointType <: StaticVector{3, T}, C <: Colorant} <: AbstractGeometry{3, T}
    position::Vector{PointType}
    color::Vector{C}
end

function FatLineGeometry(position::AbstractVector{<:AbstractVector{T}},
           color::AbstractVector{C}=RGB{Float32}[]) where {T, C <: Colorant}
    FatLineGeometry{T, Point{3, T}, C}(position, color)
end

center(geometry::HyperEllipsoid) = origin(geometry)
center(geometry::HyperRectangle) = minimum(geometry) + 0.5 * widths(geometry)
center(geometry::HyperSphere) = origin(geometry)
center(geometry::Cylinder) = (origin(geometry) + geometry.extremity) / 2
center(geometry::Cone) = (origin(geometry) + geometry.apex) / 2


"""
$(SIGNATURES)

Different tools disagree about what various geometric primitives mean. For example,
GeometryBasics.jl considers the "origin" of a cube to be its bottom-left corner, where
DrakeVisualizer and MeshCat consider its origin to be the center. The
intrinsic_transform(g) returns the transform from the GeometryBasics origin to the
MeshCat origin.
"""
intrinsic_transform(g) = IdentityTransformation()
intrinsic_transform(g::HyperRectangle) = Translation(center(g)...)
intrinsic_transform(g::HyperSphere) = Translation(center(g)...)
intrinsic_transform(g::HyperEllipsoid) = Translation(center(g)...) ∘ LinearMap(SMatrix{3, 3}(SDiagonal(radii(g)...)))

function intrinsic_transform(g::Cylinder)
    # Three.js wants a cylinder to lie along the y axis
    R = rotation_between(SVector(0, 1, 0), g.extremity - origin(g))
    Translation(center(g)) ∘ LinearMap(R)
end

function intrinsic_transform(g::Cone{3})
    # Three.js wants a cone to lie along the y axis
    R = rotation_between(SVector(0, 1, 0), g.apex - g.origin)
    Translation(center(g)) ∘ LinearMap(R)
end
