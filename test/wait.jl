# https://github.com/rdeits/MeshCat.jl/pull/99#issuecomment-509067108

@testset "wait" begin
    @testset "with setobject" begin
        vis = Visualizer()
        setobject!(vis, Triad(1.0))
        open(vis)
        if !haskey(ENV, "CI")
            wait(vis)
        end
    end

    @testset "without setobject" begin
        vis = Visualizer()
        open(vis)
        if !haskey(ENV, "CI")
            wait(vis)
        end
    end
end
