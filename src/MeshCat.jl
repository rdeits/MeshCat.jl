module MeshCat

using GeometryTypes, CoordinateTransformations
using Rotations: rotation_between, Rotation, RotMatrix, UnitQuaternion
using Colors: Color, Colorant, RGB, RGBA, alpha, hex, red, green, blue
using StaticArrays: StaticVector, SVector, SDiagonal, SMatrix
using GeometryTypes: raw
using Parameters: @with_kw
using DocStringExtensions: SIGNATURES, TYPEDSIGNATURES
using Requires: @require
using Base.Filesystem: rm
using BinDeps: download_cmd, unpack_cmd
using UUIDs: UUID, uuid1
using LinearAlgebra: UniformScaling, Diagonal, norm
using Sockets: listen, @ip_str, IPAddr, IPv4, IPv6
using Base64: base64encode
using MsgPack: MsgPack, pack
import Mux
import Logging
import Mux.WebSockets
import Cassette
import FFMPEG


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
       Mesh,
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
       atframe,
       @animation

export ArrowVisualizer

abstract type AbstractObject end
abstract type AbstractMaterial end

include("util.jl")
include("trees.jl")
using .SceneTrees
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
include("integrations.jl")

const VIEWER_ROOT = joinpath(@__DIR__, "..", "assets", "meshcat", "dist")

function __init__()
    main_js = abspath(joinpath(VIEWER_ROOT, "main.min.js"))
    if !isfile(main_js)
        error("""
        main.min.js not found at $main_js.
        Please build MeshCat using `import Pkg; Pkg.build("MeshCat")`""")
    end
    setup_integrations()
end


end
