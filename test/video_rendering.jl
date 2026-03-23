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

@testset "GIF Generation" begin
    mktempdir() do tmpdir
        target = joinpath(tmpdir, "output.gif")
        
        # Points to the existing sample data in the test folder
        input_tar = joinpath(@__DIR__, "data", "frames.tar")
        
        convert_frames_to_gif(input_tar, target)
        
        @test isfile(target)
        @test filesize(target) > 0
    end
end