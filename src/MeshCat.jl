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
using Mux

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

# TODO: https://github.com/JuliaGizmos/WebIO.jl/issues/107
# @require Blink begin
#     Base.open(vis::Visualizer, w::Blink.AtomShell.Window) = Blink.body!(w, vis.core)
# end

@require WebIO begin
    WebIO.register_renderable(CoreVisualizer)
end

end
