# GeometryTypes doesn't define an Ellipsoid type yet, so we'll make one ourselves!
struct HyperEllipsoid{N, T} <: GeometryPrimitive{N, T}
    center::Point{N, T}
    radii::Vec{N, T}
end

origin(geometry::HyperEllipsoid{N, T}) where {N, T} = geometry.center
radii(geometry::HyperEllipsoid{N, T}) where {N, T} = geometry.radii
center(geometry::HyperEllipsoid) = origin(geometry)

@deprecate HyperCylinder(length::T, radius) where {T} Cylinder{3, T}(Point(0., 0., 0.), Point(0, 0, length), radius)

struct PointCloud{T, Point <: StaticVector{3, T}, C <: Colorant} <: AbstractGeometry{3, T}
    position::Vector{Point}
    color::Vector{C}
end

function PointCloud(position::AbstractVector{<:AbstractVector{T}},
           color::AbstractVector{C}=RGB{Float32}[]) where {T, C <: Colorant}
    PointCloud{T, Point{3, T}, C}(position, color)
end


center(geometry::HyperRectangle) = minimum(geometry) + 0.5 * widths(geometry)
center(geometry::HyperCube) = minimum(geometry) + 0.5 * widths(geometry)
center(geometry::HyperSphere) = origin(geometry)

intrinsic_transform(g) = IdentityTransformation()
intrinsic_transform(g::HyperRectangle) = Translation(center(g)...)
intrinsic_transform(g::HyperSphere) = Translation(center(g)...)
intrinsic_transform(g::HyperEllipsoid) = Translation(center(g)...) ∘ LinearMap(SDiagonal(radii(g)...))
intrinsic_transform(g::HyperCube) = Translation(center(g)...)

function intrinsic_transform(g::Cylinder{3})
    # Three.js wants a cylinder to lie along the y axis
    R = rotation_between(SVector(0, 1, 0), g.extremity)
    Translation(origin(g)) ∘ LinearMap(R)
end

