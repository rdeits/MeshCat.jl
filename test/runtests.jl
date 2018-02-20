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
@testset "MeshCat" begin
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
            settransform!(v[:cat], Translation(0, -1, 0) ∘ LinearMap(RotZ(π)) ∘ LinearMap(RotX(π/2)))
        end

        @testset "textured valkyrie" begin
            head = Mesh(
                load(joinpath(MeshCat.viewer_root, "data", "head_multisense.obj"), GLUVMesh),
                MeshLambertMaterial(
                    map=Texture(
                        image=PngImage(joinpath(MeshCat.viewer_root, "data", "HeadTextureMultisense.png"))
                    )
                ))
            setobject!(v[:valkyrie, :head], head)
            settransform!(v[:valkyrie, :head], Translation(0, 0.5, 0.5))
        end
    end

    @testset "points" begin
        v = vis[:points]
        settransform!(v, Translation(-1, 0, 0))
        @testset "random points" begin
            verts = rand(Point3f0, 100000);
            colors = reinterpret(RGB{Float32}, verts);
            setobject!(v[:random], PointCloud(verts, colors))
            settransform!(v[:random], Translation(-0.5, -0.5, 0))
        end
    end
end


close(vis)

# kill(proc)
