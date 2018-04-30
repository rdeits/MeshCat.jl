__precompile__()

module MeshCat

using GeometryTypes
using CoordinateTransformations
using Rotations: rotation_between
using ZMQ

using Colors: Color, Colorant, RGB, RGBA, alpha
using StaticArrays: StaticVector, SVector, SDiagonal
using GeometryTypes: raw
using Parameters: @with_kw
using Base.Random: UUID, uuid1
using URIParser: escape
using DocStringExtensions

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
       LineBasicMaterial,
       Texture,
       PngImage,
       Mesh,
       Points,
       LineSegments,
       setobject!,
       settransform!,
       delete!,
       url

include("servers/trees.jl")
include("servers/zmqserver.jl")
using .ZMQServer: ZMQWebSocketBridge, zmq_url, web_url, VIEWER_ROOT

include("geometry.jl")
include("objects.jl")
include("commands.jl")
include("lowering.jl")
include("msgpack.jl")
include("visualizer.jl")
include("ijulia.jl")

end
