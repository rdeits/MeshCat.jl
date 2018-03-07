threejs_type(m::MeshMaterial) = m._type
threejs_type(::Mesh) = "Mesh"
threejs_type(::Points) = "Points"

"""
Convert a geometry, material, object, or transform into the appropriate
plain data structures expected by three.js. Most objects are lowered
into `Dict`s matching the JSON structure used by three.js.
"""
function lower end


function lower(t::Transformation)
    H = [transform_deriv(t, Vec(0., 0, 0)) t(Vec(0., 0, 0));
     Vec(0, 0, 0, 1)']
    reshape(H, length(H))
end

function lower(obj::AbstractObject, uuid=uuid1())
    data = Dict{String, Any}(
        "metadata" => Dict{String, Any}("version" => 4.5, "type" => "Object"),
        "object" => Dict{String, Any}(
            "uuid" => string(uuid),
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

function lower(box::HyperRectangle{3}, uuid=uuid1())
    w = widths(box)
    Dict{String, Any}(
        "uuid" => string(uuid),
        "type" => "BoxGeometry",
        "width" => max(w[1], eps(Float32)),
        "height" => max(w[2], eps(Float32)),
        "depth" => max(w[3], eps(Float32))
    )
end

lower(cube::HyperCube{3}, uuid=uuid1()) = lower(HyperRectangle(origin(cube), widths(cube)), uuid)

function lower(c::HyperCylinder{3}, uuid=uuid1())
    Dict{String, Any}(
        "uuid" => string(uuid),
        "type" => "CylinderGeometry",
        "radiusTop" => c.radius,
        "radiusBottom" => c.radius,
        "height" => max(c.length, eps(Float32)),
        "radialSegments" => 100,
    )
end

function lower(s::HyperSphere{3}, uuid=uuid1())
    Dict{String, Any}(
        "uuid" => string(uuid),
        "type" => "SphereGeometry",
        "radius" => radius(s),
        "widthSegments" => 20,
        "heightSegments" => 20,
    )
end

function lower(g::HyperEllipsoid{3}, uuid=uuid1())
    # Radius is always 1 because we handle all the
    # radii in intrinsic_transform
    Dict{String, Any}(
        "uuid" => string(uuid),
        "type" => "SphereGeometry",
        "radius" => 1,
        "widthSegments" => 20,
        "heightSegments" => 20,
    )
end

js_array_type(::Type{Float32}) = "Float32Array"
js_array_type(::Type{UInt32}) = "Uint32Array"

struct PackedVector{V <: AbstractVector}  # TODO: should require contiguous layout
    data::V
end

function lower(points::Vector{P}) where {P <: Union{StaticVector, Colorant}}
    N = length(P)
    T = eltype(P)
    Dict{String, Any}(
        "itemSize" => N,
        "type" => js_array_type(T),
        "array" => PackedVector(reinterpret(T, points, (N * length(points),))),
    )
end

to_zero_index(f::Face{N}) where {N} = SVector(raw.(convert(Face{N, OffsetInteger{-1, UInt32}}, f)))

lower(faces::Vector{<:Face}) = lower(to_zero_index.(faces))

function lower(mesh::AbstractMesh, uuid=uuid1())
    attributes = Dict{String, Any}(
        "position" => lower(convert(Vector{Point3f0}, vertices(mesh)))
    )
    if hastexturecoordinates(mesh)
        attributes["uv"] = lower(texturecoordinates(mesh))
    end
    Dict{String, Any}(
        "uuid" => string(uuid),
        "type" => "BufferGeometry",
        "data" => Dict{String, Any}(
            "attributes" => attributes,
            "index" => lower(faces(mesh))
        )
    )
end

function lower(cloud::PointCloud, uuid=uuid1())
    attributes = Dict{String, Any}(
        "position" => lower(convert(Vector{Point3f0}, cloud.position)),
    )
    if !isempty(cloud.color)
        attributes["color"] = lower(cloud.color)
    end
    Dict{String, Any}(
        "uuid" => string(uuid),
        "type" => "BufferGeometry",
        "data" => Dict(
            "attributes" => attributes
        )
    )
end

lower(color::Color) = string("0x", hex(convert(RGB, color)))

function lower(material::MeshMaterial, uuid=uuid1())
    data = Dict{String, Any}(
        "uuid" => string(uuid),
        "type" => threejs_type(material),
        "color" => lower(convert(RGB, material.color)),
        "transparent" => alpha(material.color) != 1,
        "opacity" => alpha(material.color),
        "depthFunc" => material.depthFunc,
        "depthTest" => material.depthTest,
        "depthWrite" => material.depthWrite,
        "side" => material.side,
    )
    if material.map !== nothing
        uuid = uuid1()
        data["map"] = lower(material.map)
    end
    data
end

function lower(t::Texture, uuid=uuid1())
    Dict{String, Any}(
        "uuid" => string(uuid),
        "image" => lower(t.image),
        "wrap" => t.wrap,
        "repeat" => t.repeat,
    )
end

function lower(img::PngImage, uuid=uuid1())
    Dict{String, Any}(
        "uuid" => string(uuid),
        "url" => string("data:image/png;base64,", base64encode(img.data))
    )
end

function lower(material::PointsMaterial, uuid=uuid1())
    Dict{String, Any}(
        "uuid" => string(uuid),
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