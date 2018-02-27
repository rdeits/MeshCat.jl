using Base.Test
using MeshCat
using GeometryTypes
using CoordinateTransformations
using Colors
using MeshIO, FileIO

@testset "MeshCat" begin
    include("server_client.jl")
    include("visualizer.jl")
end
