
"""
Convert a geometry, material, object, or transform into the appropriate
plain data structures expected by three.js. Most objects are lowered
into `Dict`s matching the JSON structure used by three.js.
"""
function lower end

lower(x::AbstractVector)::Vector = lower(Vector(x))  # MsgPack.jl expects native Julia vectors
lower(x::Vector) = x
lower(x::String) = x
lower(x::Union{Bool, Int32, Int64, Float32, Float64}) = x

function lower(t::Transformation)
    H = [transform_deriv(t, Vec(0., 0, 0)) t(Vec(0., 0, 0));
     Vec(0, 0, 0, 1)']
    reshape(H, length(H))
end

function lower(obj::AbstractObject)
    data = Dict{String, Any}(
        "metadata" => Dict{String, Any}("version" => 4.5, "type" => "Object"),
        "object" => Dict{String, Any}(
            "uuid" => string(uuid1()),
            "type" => threejs_type(obj),
            "matrix" => lower(intrinsic_transform(geometry(obj))),
            "geometry" => lower(geometry(obj)),
            "material" => lower(material(obj))
        )
    )
    flatten!(data)
    data
end

function replace_with_uuid!(data, field, destination_data, destination_field)
    if field in keys(data)
        obj = data[field]
        data[field] = obj["uuid"]
        push!(get!(destination_data, destination_field, []), obj)
    end
end

function flatten!(object_data::Dict)
    replace_with_uuid!(object_data["object"], "geometry", object_data, "geometries")
    replace_with_uuid!(object_data["object"], "material", object_data, "materials")
    for material in get(object_data, "materials", [])
        replace_with_uuid!(material, "map", object_data, "textures")
    end
    for texture in get(object_data, "textures", [])
        replace_with_uuid!(texture, "image", object_data, "images")
    end
end

function lower(box::HyperRectangle{3})
    w = widths(box)
    Dict{String, Any}(
        "uuid" => string(uuid1()),
        "type" => "BoxGeometry",
        "width" => max(w[1], eps(Float32)),
        "height" => max(w[2], eps(Float32)),
        "depth" => max(w[3], eps(Float32))
    )
end

lower(cube::HyperCube{3}) = lower(HyperRectangle(origin(cube), widths(cube)))

function lower(c::Cylinder{3})
    Dict{String, Any}(
        "uuid" => string(uuid1()),
        "type" => "CylinderGeometry",
        "radiusTop" => radius(c),
        "radiusBottom" => radius(c),
        "height" => max(norm(c.extremity - origin(c)), eps(Float32)),
        "radialSegments" => 100,
    )
end

function lower(s::HyperSphere{3})
    Dict{String, Any}(
        "uuid" => string(uuid1()),
        "type" => "SphereGeometry",
        "radius" => radius(s),
        "widthSegments" => 20,
        "heightSegments" => 20,
    )
end

function lower(g::HyperEllipsoid{3})
    # Radius is always 1 because we handle all the
    # radii in intrinsic_transform
    Dict{String, Any}(
        "uuid" => string(uuid1()),
        "type" => "SphereGeometry",
        "radius" => 1,
        "widthSegments" => 20,
        "heightSegments" => 20,
    )
end

function lower(g::Cone{3})
    # Radius and height are always 1 because we handle these
    # in intrinsic_transform
    Dict{String, Any}(
        "uuid" => string(uuid1()),
        "type" => "ConeGeometry",
        "radius" => g.r,
        "height" => norm(g.apex - g.origin),
        "radialSegments" => 100,
    )
end

function lower(t::Triad)
    attributes = Dict{String, Any}(
        "position" => lower([Point3f0(0, 0, 0), Point3f0(t.scale, 0, 0),
                             Point3f0(0, 0, 0), Point3f0(0, t.scale, 0),
                             Point3f0(0, 0, 0), Point3f0(0, 0, t.scale)]),
        "color" => lower([RGB{Float32}(1,0,0), RGB{Float32}(1,0.6000000238418579,0),
                          RGB{Float32}(0,1,0), RGB{Float32}(0.6000000238418579,1,0),
                          RGB{Float32}(0,0,1), RGB{Float32}(0,0.6000000238418579,1)])
    )
    Dict{String, Any}(
        "uuid" => string(uuid1()),
        "type" => "BufferGeometry",
        "data" => Dict("attributes" => attributes),
    )
end

js_array_type(::Type{Float32}) = "Float32Array"
js_array_type(::Type{UInt32}) = "Uint32Array"

struct PackedVector{T}
    data::Vector{T}
end

function lower(points::Vector{P}) where {P <: Union{StaticVector, Colorant}}
    N = length(P)
    T = eltype(P)
    Dict{String, Any}(
        "itemSize" => N,
        "type" => js_array_type(T),
        "array" => PackedVector{T}(
            reshape(reinterpret(T, points), (N * length(points),))),
    )
end

to_zero_index(f::Face{N}) where {N} = SVector(raw.(convert(Face{N, OffsetInteger{-1, UInt32}}, f)))

lower(faces::Vector{<:Face}) = lower(to_zero_index.(faces))

function lower(mesh::AbstractMesh)
    attributes = Dict{String, Any}(
        "position" => lower(convert(Vector{Point3f0}, vertices(mesh)))
    )
    if hastexturecoordinates(mesh)
        attributes["uv"] = lower(texturecoordinates(mesh))
    end
    Dict{String, Any}(
        "uuid" => string(uuid1()),
        "type" => "BufferGeometry",
        "data" => Dict{String, Any}(
            "attributes" => attributes,
            "index" => lower(faces(mesh))
        )
    )
end

lower(g::GeometryPrimitive) = lower(GLPlainMesh(g))  # Fallback for everything else (like Polyhedra.jl's Polyhedron types)

function lower(cloud::PointCloud)
    attributes = Dict{String, Any}(
        "position" => lower(convert(Vector{Point3f0}, cloud.position)),
    )
    if !isempty(cloud.color)
        attributes["color"] = lower(cloud.color)
    end
    Dict{String, Any}(
        "uuid" => string(uuid1()),
        "type" => "BufferGeometry",
        "data" => Dict(
            "attributes" => attributes
        )
    )
end

function lower(geom::MeshFileGeometry)
    Dict{String, Any}(
        "uuid" => string(uuid1()),
        "type" => "_meshfile",
        "format" => geom.format,
        "data" => pack_mesh_file_data(geom.contents))
end

# TODO: Unify these two methods once https://github.com/rdeits/meshcat/issues/50 is resolved
pack_mesh_file_data(s::AbstractString) = s
pack_mesh_file_data(s::AbstractVector{UInt8}) = PackedVector(s)

lower(color::Color) = string("0x", hex(convert(RGB, color)))

function lower(material::GenericMaterial)
    data = Dict{String, Any}(
        "uuid" => string(uuid1()),
        "type" => threejs_type(material),
        "color" => lower(convert(RGB, material.color)),
        "transparent" => alpha(material.color) != 1,
        "opacity" => alpha(material.color),
        "depthFunc" => material.depthFunc,
        "depthTest" => material.depthTest,
        "depthWrite" => material.depthWrite,
        "side" => material.side,
        "vertexColors" => material.vertexColors,
    )
    if material.map !== nothing
        data["map"] = lower(material.map)
    end
    data
end

function lower(t::Texture)
    Dict{String, Any}(
        "uuid" => string(uuid1()),
        "image" => lower(t.image),
        "wrap" => t.wrap,
        "repeat" => t.repeat,
    )
end

function lower(img::PngImage)
    Dict{String, Any}(
        "uuid" => string(uuid1()),
        "url" => string("data:image/png;base64,", base64encode(img.data))
    )
end

function lower(material::PointsMaterial)
    Dict{String, Any}(
        "uuid" => string(uuid1()),
        "type" => "PointsMaterial",
        "color" => string("0x", hex(convert(RGB, material.color))),
        "transparent" => alpha(material.color) != 1,
        "opacity" => alpha(material.color),
        "size" => material.size,
        "vertexColors" => material.vertexColors,
    )
end

lower(path::Path) = string(path)

function lower(cmd::SetObject)
    Dict{String, Any}(
        "type" => "set_object",
        "object" => lower(cmd.object),
        "path" => lower(cmd.path)
    )
end

function lower(cmd::SetTransform)
    Dict{String, Any}(
        "type" => "set_transform",
        "matrix" => PackedVector(Float32.(lower(cmd.tform))),
        "path" => lower(cmd.path)
    )
end

function lower(cmd::Delete)
    Dict{String, Any}(
        "type" => "delete",
        "path" => lower(cmd.path)
    )
end

function lower(cmd::SetProperty)
    Dict{String, Any}(
        "type" => "set_property",
        "path" => lower(cmd.path),
        "property" => lower(cmd.property),
        "value" => lower(cmd.value)
    )
end

function lower(b::Button)
    Dict{String, Any}(
        "name" => b.name,
        "callback" => string(@js((value) -> $(b.observer)[] = [$(b.name), Date.now()])),
    )
end

function lower(n::NumericControl)
    Dict{String, Any}(
        "name" => n.name,
        "callback" => string(@js((val) -> $(n.observer)[] = [$(n.name), val])),
        "value" => n.value,
        "min" => n.min,
        "max" => n.max
    )
end

function lower(cmd::SetControl)
    d = Dict{String, Any}(
        "type" => "set_control",
    )
    merge!(d, lower(cmd.control))
    d
end

function lower(track::AnimationTrack)
    Dict{String, Any}(
        "name" => string(".", track.name),
        "type" => track.jstype,
        "keys" => [Dict{String, Any}(
            "time" => track.frames[i],
            "value" => lower(track.values[i])
        ) for i in eachindex(track.frames)]
    )
end

function lower(clip::AnimationClip)
    Dict{String, Any}(
        "fps" => clip.fps,
        "name" => clip.name,
        "tracks" => [lower(t) for t in values(clip.tracks)]
    )
end

function lower(a::Animation)
    [Dict{String, Any}(
        "path" => lower(path),
        "clip" => lower(clip)
    ) for (path, clip) in a.clips]
end

function lower(cmd::SetAnimation)
    Dict{String, Any}(
        "type" => "set_animation",
        "animations" => lower(cmd.animation),
        "options" => Dict{String, Any}(
            "play" => cmd.play,
            "repetitions" => cmd.repetitions
        )
    )
end

