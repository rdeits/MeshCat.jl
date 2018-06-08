using Base.Test
using MeshCat
using GeometryTypes
using CoordinateTransformations
using Colors
using MeshIO, FileIO
using Polyhedra
using CDDLib


@testset "MeshCat" begin
    include("downloads.jl")
    include("video_rendering.jl")
    include("paths.jl")
    include("visualizer.jl")
    include("notebook.jl")

    @testset "deprecations" begin
        # Deprecated in v0.0.2
        @testset "cylinder" begin
            l = 1.0
            r = 2.0
            c = HyperCylinder(l, r)
            @test c.origin == Point(0., 0, 0)
            @test c.extremity == Point(0., 0, l)
            @test radius(c) == r
        end
    end
end
