using Test
using LinearAlgebra: UniformScaling
using MeshCat
using GeometryTypes
using CoordinateTransformations
using Colors
using MeshIO, FileIO

include("util.jl")

@testset "MeshCat" begin
    include("video_rendering.jl")
    include("paths.jl")
    include("visualizer.jl")
    include("notebook.jl")
    include("scenes.jl")
    include("wait.jl")
end

sleep(10)

module ModuleTest
    # Test for any https://github.com/JuliaLang/julia/issues/21653
    # related issues when MeshCat is included in another module
    using MeshCat
end
