__precompile__()

module MeshCat

using GeometryTypes
using CoordinateTransformations
using Rotations: rotation_between

using Colors: Color, Colorant, RGB, RGBA, alpha
using StaticArrays: StaticVector, SVector, SDiagonal
using GeometryTypes: raw
using Parameters: @with_kw
using Base.Random: UUID, uuid1
using DocStringExtensions
using Requires
using Mux: page
using WebIO
using JSExpr

import Base: delete!, length
import MsgPack: pack, Ext
import GeometryTypes: origin, radius

export Visualizer,
       ViewerWindow,
       IJuliaCell,
       HyperEllipsoid,
       HyperCylinder,
       PointCloud,
       Triad,
       PointsMaterial,
       MeshLambertMaterial,
       MeshBasicMaterial,
       MeshPhongMaterial,
       Texture,
       PngImage,
       Mesh,
       Points,
       LineSegments,
       setobject!,
       settransform!,
       delete!

include("trees.jl")
using .SceneTrees
include("geometry.jl")
include("objects.jl")
include("commands.jl")
include("lowering.jl")
include("msgpack.jl")
include("visualizer.jl")

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


end
