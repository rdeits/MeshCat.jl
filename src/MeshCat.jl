__precompile__()

module MeshCat

using GeometryTypes
using CoordinateTransformations
using WebSockets
using HttpServer

using Colors: Colorant, RGB, RGBA, alpha
using StaticArrays: StaticVector, SVector
using GeometryTypes: raw
using Parameters: @with_kw
using Base.Random: UUID, uuid1
using URIParser: escape

import Base: delete!, length
import MsgPack: pack, Ext
import GeometryTypes: origin, radius

export Visualizer,
	   IJuliaCell,
       HyperEllipsoid,
       HyperCylinder,
       PointCloud,
       PointsMaterial,
       MeshLambertMaterial,
       MeshBasicMaterial,
       MeshPhongMaterial,
       Texture,
       PngImage,
       Mesh,
       Points,
	   setobject!,
	   settransform!,
	   delete!,
	   url


include("servers.jl")
include("ijulia.jl")
include("geometry.jl")
include("objects.jl")
include("commands.jl")
include("lowering.jl")
include("msgpack.jl")
include("visualizer.jl")

end
