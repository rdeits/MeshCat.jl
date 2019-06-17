
"""
An MeshFileGeometry represents a mesh which is stored as the raw contents
of a file, rather than as a collection of points and vertices. This is useful for
transparently passing mesh files which we can't load in Julia directly to meshcat.

Supported formats:
    * .stl (ASCII and binary)
    * .obj
    * .dae (Collada)

For .obj and .dae files, only a single mesh geometry will be loaded, and any
material or texture properties will be ignored. To load an entire collection of
objects (complete with materials and textures) from an .obj or .dae file, see
MeshFileObject instead.
"""
struct MeshFileGeometry{S <: Union{String, Vector{UInt8}}}
    contents::S
    format::String
end

function MeshFileGeometry(filename)
    ext = lowercase(splitext(filename)[2])
    if ext ∈ (".obj", ".dae")
        MeshFileGeometry(open(f -> read(f, String), filename), ext[2:end])
    elseif ext == ".stl"
        MeshFileGeometry(open(read, filename), ext[2:end])
    else
        throw(ArgumentError("Unsupported extension: $ext. Only .obj, .dae, and .stl meshes can be used to construct MeshFileGeometry"))
    end
end


"""
A MeshFileObject is similar to a MeshFileGeometry, but rather than representing
a single geometry, it supports loading an entire object (with geometries,
materials, and textures), or even a collection of objects (for supported file
types).

Supported formats:
    * .obj
    * .dae (Collada)

Since mesh files may include references to other files (such as texture images),
the MeshFileObject also includes a `resources` dictionary mapping relative paths
(as specified in the mesh file) to the contents of the referenced files. Those contents are specified using data URIs, e.g.:

    data:image/png;base64,<base-64 encoded data here>

If you construct a MeshFileObject from a `.dae` or `.obj` file, the resources
dictionary will automatically be populated.
"""
struct MeshFileObject <: AbstractObject
    contents::String
    format::String
    mtl_library::Union{String, Nothing}
    resources::Dict{String, String}
end

function MeshFileObject(filename)
    ext = lowercase(splitext(filename)[2])
    if ext ∉ (".obj", ".dae")
        throw(ArgumentError("Unsupported extension: $ext. Only .obj and .dae meshes can be used to construct MeshFileObject"))
    end
    contents = open(f -> read(f, String), filename)
    format = ext[2:end]
    if ext == ".obj"
        mtl_library = load_mtl_library(contents, dirname(filename))
        resources = load_mtl_textures(mtl_library, dirname(filename))
    else
        mtl_library = nothing
        resources = load_dae_textures(contents, dirname(filename))
    end
    MeshFileObject(contents, format, mtl_library, resources)
end

function load_mtl_library(obj_contents, directory=".")
    libraries = String[]
    for line in eachline(IOBuffer(obj_contents))
        m = match(r"^mtllib (.*)$", line)
        if m !== nothing
            push!(libraries, open(f -> read(f, String), joinpath(directory, m.captures[1])))
        end
    end
    join(libraries, '\n')
end

data_uri(contents::Vector{UInt8}) = string("data:image/png;base64,", base64encode(contents))

function load_mtl_textures(mtl_contents, directory=".")
    textures = Dict{String, String}()
    for line in eachline(IOBuffer(mtl_contents))
        m = match(r"^map_[^ ]* (.*)$", line)
        if m !== nothing
            name = m.captures[1]
            contents = open(read, joinpath(directory, name))
            textures[name] = data_uri(contents)
        end
    end
    textures
end

function load_dae_textures(dae_contents, directory=".")
    # TODO: this is probably not a very robust parsing strategy,
    # but I don't have enough examples to work from to decide on a
    # better one, so I'm keeping it simple.
    r = r"\<image [^\>]*\>\s*<init_from\>([^\<]*)\<\/init_from\>"m
    textures = Dict{String, String}()
    for match in eachmatch(r, dae_contents)
        name = match.captures[1]
        textures[name] = data_uri(open(read, joinpath(directory, name)))
    end
    textures
end
