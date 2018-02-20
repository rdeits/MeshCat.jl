const GeometryLike = Union{AbstractGeometry, AbstractMesh}
abstract type AbstractObject end
abstract type AbstractMaterial end

struct Mesh{G <: GeometryLike, M <: AbstractMaterial} <: AbstractObject
	geometry::G
	material::M
end

geometry(o::Mesh) = o.geometry
material(o::Mesh) = o.material

Mesh(geometry::GeometryLike) = Mesh(geometry, MeshLambertMaterial())

struct PngImage
    data::Vector{UInt8}
end

PngImage(fname::AbstractString) = PngImage(open(read, fname))

@with_kw struct Texture
    image::PngImage
    wrap::Tuple{Int, Int} = (1001, 1001)  # TODO: replace with enum
    repeat::Tuple{Int, Int} = (1, 1)      # TODO: what does this mean?
end

@with_kw struct MeshMaterial <: AbstractMaterial
	_type::String
	color::RGBA{Float32} = RGB(1., 1., 1.)
    map::Union{Texture, Void} = nothing
    depthFunc::Int = 3
    depthTest::Bool = true
    depthWrite::Bool = true
    emissive::Float32 = 0
end

MeshBasicMaterial(;kw...) = MeshMaterial(_type="MeshBasicMaterial"; kw...)
MeshLambertMaterial(;kw...) = MeshMaterial(_type="MeshLambertMaterial"; kw...)
MeshPhongMaterial(;kw...) = MeshMaterial(_type="MeshPhongMaterial"; kw...)

struct Points{G <: GeometryLike, M <: AbstractMaterial} <: AbstractObject
    geometry::G
    material::M
end

geometry(p::Points) = p.geometry
material(p::Points) = p.material

@with_kw struct PointsMaterial <: AbstractMaterial
    color::RGBA{Float32}=RGB(1., 1., 1.)
    size::Float32 = 0.002
    vertexColors::Int = 2
end

Points(geometry::GeometryLike; kw...) = Points(geometry, PointsMaterial(kw...))


quaternion_xyzw(::IdentityTransformation) = SVector(0., 0, 0, 1)
quaternion_xyzw(tform::AbstractAffineMap) = quaternion_xyzw(transform_deriv(tform, SVector(0., 0, 0)))
quaternion_xyzw(matrix::UniformScaling) = quaternion_xyzw(IdentityTransformation())
quaternion_xyzw(matrix::AbstractMatrix) = quaternion_xyzw(Quat(matrix))
quaternion_xyzw(quat::Quat) = SVector(quat.x, quat.y, quat.z, quat.w)

translation(tform::Transformation) = tform(SVector(0., 0, 0))
