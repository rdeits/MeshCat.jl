module MeshCat

using GeometryBasics: GeometryBasics,
  AbstractGeometry,
  AbstractMesh,
  AbstractNgonFace,
  AbstractFace,
  Cylinder,
  GLTriangleFace,
  GeometryPrimitive,
  HyperRectangle,
  HyperSphere,
  MetaMesh,
  NgonFace,
  OffsetInteger,
  Point,
  Point3f,
  Polytope,
  SimplexFace,
  Vec,
  decompose,
  meta,
  origin,
  radius,
  texturecoordinates,
  raw,
  widths

using CoordinateTransformations
using Rotations: params, rotation_between, Rotation, RotMatrix, QuatRotation
using Colors: Color, Colorant, RGB, RGBA, alpha, hex, red, green, blue
using StaticArrays: StaticVector, SVector, SDiagonal, SMatrix
using Parameters: @with_kw
using DocStringExtensions: SIGNATURES, TYPEDSIGNATURES
using Base.Filesystem: rm
using UUIDs: uuid1
using LinearAlgebra: UniformScaling, Diagonal, norm
using Sockets: listen, @ip_str, IPAddr
using Base64: base64encode
using MsgPack: MsgPack, pack
using Pkg.Artifacts: @artifact_str
import FFMPEG
import HTTP
import Logging
import Tar


import Base: delete!

export Visualizer,
       IJuliaCell,
       render,
       render_static,
       static_html

export setobject!,
       settransform!,
       delete!,
       setprop!,
       setanimation!,
       save_image,
       setvisible!

export AbstractVisualizer,
       AbstractMaterial,
       AbstractObject,
       GeometryLike

export Object,
       HyperEllipsoid,
       PointCloud,
       Cone,
       Triad,
       MeshObject,
       MeshFileGeometry,
       MeshFileObject,
       Points,
       Line,
       LineLoop,
       LineSegments

export PointsMaterial,
       MeshLambertMaterial,
       MeshBasicMaterial,
       MeshPhongMaterial,
       LineBasicMaterial,
       Texture,
       PngImage

export Animation,
       atframe

export ArrowVisualizer

abstract type AbstractObject end
abstract type AbstractMaterial end

include("util.jl")
include("trees.jl")
using .SceneTrees

struct AnimationContext
    animation
    frame::Int
end

"""
Low-level type which manages the actual meshcat server. See [`Visualizer`](@ref)
for the public-facing interface.
"""
mutable struct CoreVisualizer
    tree::SceneNode
    connections::Set{HTTP.WebSockets.WebSocket}
    host::IPAddr
    port::Int
    server::HTTP.Server
    animation_contexts::Vector{AnimationContext}

    function CoreVisualizer(host::IPAddr = ip"127.0.0.1", default_port=8700)
        connections = Set([])
        tree = SceneNode()
        port = find_open_port(host, default_port, 500)
        core = new(tree, connections, host, port)
        core.server = start_server(core)
        core.animation_contexts = AnimationContext[]
        return core
    end
end

include("mesh_files.jl")
include("geometry.jl")
include("objects.jl")
include("animations.jl")
include("commands.jl")
include("abstract_visualizer.jl")
include("lowering.jl")
include("msgpack.jl")
include("visualizer.jl")
include("atframe.jl")
include("arrow_visualizer.jl")
include("render.jl")
include("servers.jl")
include("assets.jl")

VIEWER_ROOT() = joinpath(first(readdir(artifact"meshcat", join=true)), "dist")
const MAIN_JS_STRING = read(joinpath(VIEWER_ROOT(), "main.min.js"), String)
const INDEX_HTML_STRING = read(joinpath(VIEWER_ROOT(), "index.html"), String)

# Code to "exercise" the package - see https://julialang.github.io/PrecompileTools.jl/stable/
include("./precompile.jl")

end
