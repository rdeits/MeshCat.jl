# https://github.com/rdeits/MeshCat.jl/pull/99#issuecomment-509067108

@testset "wait" begin
    @testset "with setobject" begin
        vis = Visualizer()
        setobject!(vis, Triad(1.0))
        if !haskey(ENV, "CI")
            open(vis)
            wait(vis)
        end
    end

    @testset "without setobject" begin
        vis = Visualizer()
        if !haskey(ENV, "CI")
            open(vis)
            wait(vis)
        end
    end
end
