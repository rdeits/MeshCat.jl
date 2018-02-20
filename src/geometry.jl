# GeometryTypes doesn't define an Ellipsoid type yet, so we'll make one ourselves!
struct HyperEllipsoid{N, T} <: GeometryPrimitive{N, T}
    center::Point{N, T}
    radii::Vec{N, T}
end

origin(geometry::HyperEllipsoid{N, T}) where {N, T} = geometry.center
radii(geometry::HyperEllipsoid{N, T}) where {N, T} = geometry.radii
center(geometry::HyperEllipsoid) = origin(geometry)

struct HyperCylinder{N, T} <: GeometryPrimitive{N, T}
    length::T # along last axis
    radius::T
    # origin is at center
end

HyperCylinder(length, radius) =
    HyperCylinder{3, promote_type(typeof(length), typeof(radius))}(length, radius)

length(geometry::HyperCylinder) = geometry.length
radius(geometry::HyperCylinder) = geometry.radius
origin(geometry::HyperCylinder{N, T}) where {N, T} = zeros(SVector{N, T})
center(g::HyperCylinder) = origin(g)


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
intrinsic_transform(g::HyperEllipsoid) = LinearMap(SDiagonal(radii(g)...)) ∘ Translation(center(g)...)
intrinsic_transform(g::HyperCylinder{3}) = LinearMap(RotX(π/2)) ∘ Translation(center(g)...)
intrinsic_transform(g::HyperCube) = Translation(center(g)...)

