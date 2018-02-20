using Base.Test
using MeshCat
using GeometryTypes
using CoordinateTransformations
using Colors
using MeshIO, FileIO

vis = Visualizer()

if get(ENV, "CI", nothing) == "true"
    stream, proc = open(`julia $(joinpath(@__DIR__, "socket_client.jl")) ws://$(vis.core.window.host):$(vis.core.window.port)`)
else
    open(vis)
end

@testset "shapes" begin
    v = vis[:shapes]
    settransform!(v, Translation(1., 0, 0))
    @testset "cube" begin
        setobject!(v[:cube], HyperRectangle(Vec(0., 0, 0), Vec(0.1, 0.2, 0.3)))
    end

    @testset "cylinder" begin
        setobject!(v[:cylinder], Mesh(
           HyperCylinder(0.2, 0.1),
           MeshLambertMaterial(color=colorant"lime")))
        settransform!(v[:cylinder], Translation(0, 0.5, 0.1))
    end

    @testset "sphere" begin
        setobject!(v[:sphere], Mesh(
            HyperSphere(Point(0., 0, 0), 0.15),
            MeshLambertMaterial(color=colorant"maroon")))
        settransform!(v[:sphere], Translation(0, 1, 0.15))
    end

    @testset "ellipsoid" begin
        setobject!(v[:ellipsoid], HyperEllipsoid(Point(0., 0, 0), Vec(0.3, 0.1, 0.1)))
        settransform!(v[:ellipsoid], Translation(0, 1.5, 0.1))
    end
end

@testset "meshes" begin
    v = vis[:meshes]
    @testset "cat" begin
        mesh = load(joinpath(Pkg.dir("GeometryTypes"), "test", "data", "cat.obj"))
        setobject!(v[:cat], mesh)
        settransform!(vis[:cat], LinearMap(RotX(π/2)))
    end
end

close(vis)

# kill(proc)
