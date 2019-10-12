__precompile__()

module MeshCat

using WebIO
import Mux
import AssetRegistry
import Cassette
using GeometryTypes, CoordinateTransformations
using Rotations: rotation_between, Rotation, Quat
using Colors: Color, Colorant, RGB, RGBA, alpha, hex
using StaticArrays: StaticVector, SVector, SDiagonal, SMatrix
using GeometryTypes: raw
using Parameters: @with_kw
using DocStringExtensions: SIGNATURES
using JSExpr: @js, @new, @var
using Requires: @require
using Base.Filesystem: rm
using BinDeps: download_cmd, unpack_cmd
using UUIDs: UUID, uuid1
using LinearAlgebra: UniformScaling, Diagonal, norm
using Sockets: listen, @ip_str, IPAddr, IPv4, IPv6
using Base64: base64encode
using MsgPack: MsgPack, pack

import Base: delete!

export Visualizer,
       ViewerWindow,
       IJuliaCell

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
       HyperCylinder,
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
include("servers.jl")

const VIEWER_ROOT = joinpath(@__DIR__, "..", "assets", "meshcat", "dist")

function develop_meshcat_assets(skip_confirmation=false)
    meshcat_dir = abspath(joinpath(@__DIR__, "..", "assets", "meshcat"))
    if !skip_confirmation
        println("CAUTION: This will delete all downloaded meshcat assets and replace them with a git clone.")
        println("The following path will be overwritten:")
        println(meshcat_dir)
        println("To undo this operation, you will need to manually remove that directory and then run `Pkg.build(\"MeshCat\")`")
        print("Proceed? (y/n) ")
        choice = chomp(readline())
        if isempty(choice) || lowercase(choice[1]) != 'y'
            println("Canceled.")
            return
        end
    end
    println("Removing $meshcat_dir")
    rm(meshcat_dir, force=true, recursive=true)
    run(`git clone https://github.com/rdeits/meshcat $meshcat_dir`)
    rm(joinpath(meshcat_dir, "..", "meshcat.stamp"))
end

const ASSET_KEYS = String[]

function __init__()
    main_js = abspath(joinpath(VIEWER_ROOT, "main.min.js"))
    if !isfile(main_js)
        error("""
        main.min.js not found at $main_js.
        Please build MeshCat using `import Pkg; Pkg.build("MeshCat")`""")
    end
    push!(ASSET_KEYS, AssetRegistry.register(main_js))

    @require Blink="ad839575-38b3-5650-b840-f874b8c74a25" begin
        function Base.open(core::CoreVisualizer, w::Blink.AtomShell.Window)
            # Ensure the window is ready
            Blink.js(w, "ok")
            # Set its contents
            Blink.body!(w, core.scope)
            w
        end
    end
end

end
