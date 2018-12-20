# GeometryTypes doesn't define an Ellipsoid type yet, so we'll make one ourselves!
struct HyperEllipsoid{N, T} <: GeometryPrimitive{N, T}
    center::Point{N, T}
    radii::Vec{N, T}
end

GeometryTypes.origin(geometry::HyperEllipsoid{N, T}) where {N, T} = geometry.center
radii(geometry::HyperEllipsoid{N, T}) where {N, T} = geometry.radii

@deprecate HyperCylinder(length::T, radius) where {T} Cylinder{3, T}(Point(0., 0., 0.), Point(0, 0, length), radius)

struct PointCloud{T, Point <: StaticVector{3, T}, C <: Colorant} <: AbstractGeometry{3, T}
    position::Vector{Point}
    color::Vector{C}
end

function PointCloud(position::AbstractVector{<:AbstractVector{T}},
           color::AbstractVector{C}=RGB{Float32}[]) where {T, C <: Colorant}
    PointCloud{T, Point{3, T}, C}(position, color)
end

struct Triad <: AbstractGeometry{3, Float64}
    scale::Float64

    Triad(scale=20.0) = new(scale)
end

struct Cone{N, T} <: AbstractGeometry{N, T}
    origin::Point{N, T}
    apex::Point{N, T}
    r::T
end

GeometryTypes.origin(geometry::Cone) = geometry.origin

center(geometry::HyperEllipsoid) = origin(geometry)
center(geometry::HyperRectangle) = minimum(geometry) + 0.5 * widths(geometry)
center(geometry::HyperCube) = minimum(geometry) + 0.5 * widths(geometry)
center(geometry::HyperSphere) = origin(geometry)
center(geometry::Cylinder) = (origin(geometry) + geometry.extremity) / 2
center(geometry::Cone) = (origin(geometry) + geometry.apex) / 2

"""
$(SIGNATURES)

Different tools disagree about what various geometric primitives mean. For example,
GeometryTypes.jl considers the "origin" of a cube to be its bottom-left corner, where
DrakeVisualizer and MeshCat consider its origin to be the center. The
intrinsic_transform(g) returns the transform from the GeometryTypes origin to the
MeshCat origin.
"""
intrinsic_transform(g) = IdentityTransformation()
intrinsic_transform(g::HyperRectangle) = Translation(center(g)...)
intrinsic_transform(g::HyperSphere) = Translation(center(g)...)
intrinsic_transform(g::HyperEllipsoid) = Translation(center(g)...) ∘ LinearMap(SMatrix{3, 3}(SDiagonal(radii(g)...)))
intrinsic_transform(g::HyperCube) = Translation(center(g)...)

function intrinsic_transform(g::Cylinder{3})
    # Three.js wants a cylinder to lie along the y axis
    R = rotation_between(SVector(0, 1, 0), g.extremity - origin(g))
    Translation(center(g)) ∘ LinearMap(R)
end

function intrinsic_transform(g::Cone{3})
    # Three.js wants a cone to lie along the y axis
    R = rotation_between(SVector(0, 1, 0), g.apex - g.origin)
    Translation(center(g)) ∘ LinearMap(R)
end
