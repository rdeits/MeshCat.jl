using Base.Test
using MeshCat
using GeometryTypes
using CoordinateTransformations
using Colors
using MeshIO, FileIO

@testset "MeshCat" begin
    include("geometry.jl")
    include("server_client.jl")
    include("visualizer.jl")
    include("notebook.jl")
end
