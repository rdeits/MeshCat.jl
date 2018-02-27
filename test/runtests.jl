using Base.Test
using MeshCat
using GeometryTypes
using CoordinateTransformations
using Colors
using MeshIO, FileIO

@testset "MeshCat" begin
    include("visualizer.jl")
    include("server_client.jl")
end
