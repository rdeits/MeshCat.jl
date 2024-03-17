using Test
using MeshCat
using FileIO
using CoordinateTransformations

# Demonstrate a couple of different lighting configurations, and
# show how the lighting settings can be manipulated programmatically.
@testset "Lighting Scenes" begin
    cat_mesh_path = joinpath(@__DIR__, "data", "meshes", "cat.obj")
    cat = load(cat_mesh_path)

    function add_cats!(vis::Visualizer)
        setobject!(vis["floor"], Rect(Vec(-10, -10, -0.01), Vec(20, 20, 0.01)))
        for x in range(-5, stop=5, step=2)
            for y in range(-5, stop=5, step=2)
                setobject!(vis["cat"][string(x)][string(y)], cat)
                settransform!(vis["cat"][string(x)][string(y)],
                    Translation(x, y, 0) ∘
                    LinearMap(RotZ(Float64(π))) ∘ LinearMap(RotX(π/2)))
            end
        end
    end

    @testset "Default" begin
        vis = Visualizer()
        if !haskey(ENV, "CI")
            open(vis)
            wait(vis)
        end
        add_cats!(vis)
    end

    @testset "SpotLight with shadows" begin
        vis = Visualizer()
        if !haskey(ENV, "CI")
            open(vis)
            wait(vis)
        end
        add_cats!(vis)
        setprop!(vis["/Lights/SpotLight"], "visible", true)
        # To understand why we need the <object> here, see the documentation for
        # set_property at https://github.com/meshcat-dev/meshcat
        setprop!(vis["/Lights/SpotLight/<object>"], "castShadow", true)
        setprop!(vis["/Lights/DirectionalLight"], "visible", false)
        # To understand why we need the <object> here, see the documentation for
        # set_property at https://github.com/meshcat-dev/meshcat
        setprop!(vis["/Lights/AmbientLight/<object>"], "intensity", 0.44)
    end
end

@testset "Background" begin
    @testset "Background color" begin
        vis = Visualizer()
        if !haskey(ENV, "CI")
            open(vis)
            wait(vis)
        end
        setprop!(vis["/Background"], "top_color", colorant"red")
    end

    @testset "Background hidden" begin
        vis = Visualizer()
        if !haskey(ENV, "CI")
            open(vis)
            wait(vis)
        end
        setprop!(vis["/Background"], "visible", false)
    end

end