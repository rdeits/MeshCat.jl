using Blink
import GeometryTypes

notinstalled = !AtomShell.isinstalled()
notinstalled && AtomShell.install()

window = Window()
vis = Visualizer()

if !haskey(ENV, "CI")
    open(vis)
end

if !(Sys.iswindows() && haskey(ENV, "CI"))
    # this gets stuck on windows CI, but I don't know why
    open(vis, window)
end

if !haskey(ENV, "CI")
    wait(vis)
end

# A custom geometry type to test that we can render arbitrary primitives
# by decomposing them into simple meshes. This replaces the previous test
# which did the same thing using a Polyhedron from Polyhedra.jl. The Polyhedra
# test was removed because it required too many external dependencies just to
# verify a simple interface.
struct CustomGeometry <: GeometryPrimitive{3, Float64}
end

GeometryTypes.isdecomposable(::Type{<:Face}, ::CustomGeometry) = true
function GeometryTypes.decompose(::Type{F}, c::CustomGeometry) where {F <: Face}
    [convert(F, Face(1,2,3))]
end
GeometryTypes.isdecomposable(::Type{<:Point}, ::CustomGeometry) = true
function GeometryTypes.decompose(::Type{P}, c::CustomGeometry) where {P <: Point}
    convert(Vector{P}, [Point(0., 0, 0), Point(0., 1, 0), Point(0., 0, 1)])
end

@testset "self-contained visualizer" begin
    cat_mesh_path = joinpath(dirname(pathof(GeometryTypes)), "..", "test", "data", "cat.obj")

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
            setobject!(v[:cylinder2], Cylinder(Point(0, 2.5, 0), Point(0.1, 2.6, 0), 0.05))
            settransform!(v[:cylinder2], Translation(0, 0, 0.05))
        end

        @testset "triad" begin
            setobject!(v[:triad], Triad(0.2))
            settransform!(v[:triad], Translation(0, 3, 0.2))
        end

        @testset "cone" begin
            setobject!(v[:cone],
                Cone(Point(1., 1., 1.), Point(1., 1., 1.2), 0.1),
                MeshLambertMaterial(color=colorant"indianred"))
            settransform!(v[:cone], Translation(-1, 2.5, -1))
        end
    end

    @testset "meshes" begin
        v = vis[:meshes]
        @testset "cat" begin
            mesh = load(cat_mesh_path)
            setobject!(v[:cat], mesh)
            settransform!(v[:cat], Translation(0, -1, 0) ∘ LinearMap(RotZ(π)) ∘ LinearMap(RotX(π/2)))
        end

        @testset "cat_color" begin
            mesh = load(cat_mesh_path)
            color = RGBA{Float32}(0.5, 0.5, 0.5, 0.5)
            mesh_color = HomogenousMesh(vertices=mesh.vertices, faces=mesh.faces, color=color)
            object = Object(mesh_color)
            @test MeshCat.material(object).color == color
            mesh_color = setobject!(v[:cat_color], mesh_color)
            settransform!(v[:cat_color], Translation(0, -2.0, 0) ∘ LinearMap(RotZ(π)) ∘ LinearMap(RotX(π/2)))
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

    @testset "points with material (Issue #58)" begin
        v = vis[:points_with_material]
        settransform!(v, Translation(-1.5, -2.5, 0))
        material = PointsMaterial(color=RGBA(0,0,1,0.5))
        cloud = PointCloud(rand(Point3f0, 5000))
        obj = Object(cloud, material)
        @test MeshCat.threejs_type(obj) == "Points"
        setobject!(v, cloud, material)
    end

    @testset "lines" begin
        v = vis[:lines]
        settransform!(v, Translation(-1, -1, 0))
        @testset "LineSegments" begin
            θ = range(0, stop=2π, length=10)
            setobject!(v[:line_segments], LineSegments(Point.(0.5 .* sin.(θ), 0, 0.5 .* cos.(θ))))
        end
        @testset "Line" begin
            θ = range(0, stop=2π, length=10)
            setobject!(v[:line], Line(Point.(0.5 .* sin.(θ), 0, 0.5 .* cos.(θ))))
            settransform!(v[:line], Translation(0, 0.1, 0))
        end
        @testset "LineLoop" begin
            θ = range(0, stop=π, length=10)
            setobject!(v[:line_loop], LineLoop(Point.(0.5 .* sin.(θ), 0, 0.5 .* cos.(θ))))
            settransform!(v[:line_loop], Translation(0, 0.2, 0))
        end
    end

    @testset "Custom geometry primitives" begin
        primitive = CustomGeometry()
        setobject!(vis[:custom], primitive)
        settransform!(vis[:custom],  Translation(-0.5, 1.0, 0) ∘ LinearMap(UniformScaling(0.5)))
    end

    @testset "Animation" begin
        anim = Animation()
        atframe(anim, vis[:shapes], 0) do frame_vis
            settransform!(frame_vis[:box], Translation(0., 0, 0))
        end
        atframe(anim, vis[:shapes], 30) do frame_vis
            settransform!(frame_vis[:box], Translation(2., 0, 0) ∘ LinearMap(RotZ(π/2)))
        end
        atframe(anim, vis, 0) do framevis
            setprop!(framevis["/Cameras/default/rotated/<object>"], "zoom", 1)
        end

        atframe(anim, vis, 30) do framevis
            setprop!(framevis["/Cameras/default/rotated/<object>"], "zoom", 0.5)
        end
        setanimation!(vis, anim)
    end
end

sleep(5)

if !(Sys.iswindows() && haskey(ENV, "CI"))
    # this also fails on appveyor, and again I have no way to debug it
    notinstalled && AtomShell.uninstall()
end
