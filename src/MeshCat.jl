__precompile__()

module MeshCat

using GeometryTypes
using CoordinateTransformations
using Rotations: rotation_between, Rotation

using Colors: Color, Colorant, RGB, RGBA, alpha
using StaticArrays: StaticVector, SVector, SDiagonal
using GeometryTypes: raw
using Parameters: @with_kw
using Compat.UUIDs: UUID, uuid1
using DocStringExtensions
using Requires: @require
using Mux: page
using WebIO
using JSExpr
using Base.Filesystem: rm
using BinDeps: download_cmd, unpack_cmd

import Base: delete!, length
import MsgPack: pack, Ext
import GeometryTypes: origin, radius

export Visualizer,
       ViewerWindow,
       IJuliaCell

export setobject!,
       settransform!,
       delete!,
       setprop!,
       setanimation!

export AbstractVisualizer,
       AbstractMaterial,
       AbstractObject,
       GeometryLike

export Object,
       HyperEllipsoid,
       HyperCylinder,
       PointCloud,
       Triad,
       Mesh,
       Points,
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




include("trees.jl")
using .SceneTrees
include("geometry.jl")
include("objects.jl")
include("animations.jl")
include("commands.jl")
include("abstract_visualizer.jl")
include("lowering.jl")
include("msgpack.jl")
include("visualizer.jl")
include("animation_visualizer.jl")

const VIEWER_ROOT = joinpath(@__DIR__, "..", "assets", "meshcat", "dist")

Base.open(vis::Visualizer, args...; kw...) = open(vis.core, args...; kw...)

function Base.open(core::CoreVisualizer, port::Integer)
    WebIO.webio_serve(page("/", req -> core.scope), port)
    url = "http://127.0.0.1:$port"
    info("Serving MeshCat visualizer at $url")
    open_url(url)
end

function open_url(url)
    try
        if is_windows()
            run(`start $url`)
        elseif is_apple()
            run(`open $url`)
        elseif is_linux()
            run(`xdg-open $url`)
        end
    catch e
        println("Could not open browser automatically: $e")
        println("Please open the following URL in your browser:")
        println(url)
    end
end

function Base.open(core::CoreVisualizer; default_port=8700, max_retries=500)
    for port in default_port + (0:max_retries)
        server = try
            listen(port)
        catch e
            if e isa Base.UVError
                continue
            end
        end
        close(server)
        # It is *possible* that a race condition could occur here, in which
        # some other process grabs the given port in between the close() above
        # and the open() below. But it's unlikely and would not be terribly
        # damaging (the user would just have to call open() again).
        return open(core, port)
    end
end

@require Blink begin
    function Base.open(core::CoreVisualizer, w::Blink.AtomShell.Window)
        # Ensure the window is ready
        Blink.js(w, "ok")
        # Set its contents
        Blink.body!(w, core.scope)
        w
    end
end

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

end
