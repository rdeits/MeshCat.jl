using Base.Test
using MeshCat
using GeometryTypes
using CoordinateTransformations
using Colors

vis = open(Visualizer())

if get(ENV, "CI", nothing) == "true"
    proc, listener = open(`python3 $(joinpath(@__DIR__, "socket_client.py")) ws://$(vis.core.window.host):$(vis.core.window.port)`)
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
