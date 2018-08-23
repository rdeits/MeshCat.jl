using Compat
using Compat.Test
using Compat.LinearAlgebra: UniformScaling
using MeshCat
using GeometryTypes
using CoordinateTransformations
using Colors
using MeshIO, FileIO

@testset "MeshCat" begin
    include("video_rendering.jl")
    include("paths.jl")
    include("visualizer.jl")
    include("notebook.jl")
end

module ModuleTest
    # Test for any https://github.com/JuliaLang/julia/issues/21653
    # related issues when MeshCat is included in another module
    using MeshCat
end
