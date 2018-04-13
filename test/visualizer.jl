vis = Visualizer()

if haskey(ENV, "CI")
    port = split(split(url(vis), ':')[end], '/')[1]
    @show port
    stream, proc = open(`julia $(joinpath(@__DIR__, "dummy_websocket_client.jl")) $port`)
else
    proc = nothing
    open(vis)
end

wait(vis)
delete!(vis)

@testset "self-contained visualizer" begin
    @testset "shapes" begin
        v = vis[:shapes]
        delete!(v)
        settransform!(v, Translation(1., 0, 0))
        @testset "box" begin
            setobject!(v[:box], HyperRectangle(Vec(0., 0, 0), Vec(0.1, 0.2, 0.3)))
            settransform!(v[:box], Translation(-0.05, -0.1, 0))
        end

        @testset "cylinder" begin
            setobject!(v[:cylinder], Mesh(
               Cylinder(Point(0., 0, 0), Point(0, 0, 0.2), 0.1),
               MeshLambertMaterial(color=colorant"lime")))
            settransform!(v[:cylinder], Translation(0, 0.5, 0.0))
        end

        @testset "sphere" begin
            setobject!(v[:sphere],
                HyperSphere(Point(0., 0, 0), 0.15),
                MeshLambertMaterial(color=colorant"maroon"))
            settransform!(v[:sphere], Translation(0, 1, 0.15))
        end

        @testset "ellipsoid" begin
            setobject!(v[:ellipsoid], HyperEllipsoid(Point(0., 1.5, 0), Vec(0.3, 0.1, 0.1)))
            settransform!(v[:ellipsoid], Translation(0, 0, 0.1))
        end

        @testset "cube" begin
            setobject!(v[:cube], HyperCube(Vec(-0.1, -0.1, 0), 0.2), MeshBasicMaterial())
            settransform!(v[:cube], Translation(0, 2.0, 0))
        end

        @testset "more complicated cylinder" begin
            setobject!(v[:cylinder2], Cylinder(Point(0, 2.5, 0), Point(0.1, 0.1, 0), 0.05))
            settransform!(v[:cylinder2], Translation(0, 0, 0.05))
        end

        @testset "triad" begin
            setobject!(v[:triad], Triad(0.2))
            settransform!(v[:triad], Translation(0, 3, 0.2))
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
                load(joinpath(MeshCat.VIEWER_ROOT, "..", "data", "head_multisense.obj"), GLUVMesh),
                MeshLambertMaterial(
                    map=Texture(
                        image=PngImage(joinpath(MeshCat.VIEWER_ROOT, "..", "data", "HeadTextureMultisense.png"))
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


    @testset "Polyhedra" begin
        ext1 = SimpleVRepresentation([0 1 2 3;0 2 1 3; 1 0 2 3; 1 2 0 3; 2 0 1 3; 2 1 0 3;
                                    0 1 3 2;0 3 1 2; 1 0 3 2; 1 3 0 2; 3 0 1 2; 3 1 0 2;
                                    0 3 2 1;0 2 3 1; 3 0 2 1; 3 2 0 1; 2 0 3 1; 2 3 0 1;
                                    3 1 2 0;3 2 1 0; 1 3 2 0; 1 2 3 0; 2 3 1 0; 2 1 3 0])
        poly1 = CDDPolyhedron{4,Rational{BigInt}}(ext1)

        poly2 = project(poly1, [1 1 1; -1 1 1; 0 -2 1; 0 0 -3])
        setobject!(vis[:polyhedron], poly2)
        settransform!(vis[:polyhedron],  Translation(-0.5, 1.0, 0) ∘ LinearMap(UniformScaling(0.1)))
    end

end

close(vis)

if proc !== nothing
    kill(proc)
end