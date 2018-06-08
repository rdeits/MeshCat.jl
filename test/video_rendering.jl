using Base.Filesystem: rm

@testset "video rendering" begin
    has_ffmpeg = false
    try
        run(`ffmpeg -version`)
        has_ffmpeg = true
    catch e
    end
    if has_ffmpeg
        mktempdir() do tmpdir
            target = joinpath(tmpdir, "output.mp4")
            MeshCat.convert_frames_to_video(
                joinpath(@__DIR__, "data", "frames.tar"),
                target)
            @test isfile(target)
        end
    end
end
