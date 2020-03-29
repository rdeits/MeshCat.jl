using Base.Filesystem: rm

@testset "video rendering" begin
    if VERSION >= v"1.3-"
        # Prior to Julia 1.3, we can't use the new FFMPEG_jll binaries
        # which ensure that FFMPEG is available.
        mktempdir() do tmpdir
            target = joinpath(tmpdir, "output.mp4")
            MeshCat.convert_frames_to_video(
                joinpath(@__DIR__, "data", "frames.tar"),
                target)
            @test isfile(target)
        end
    end
end
