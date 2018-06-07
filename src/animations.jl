
struct AnimationTrack{T}
    name::String
    jstype::String
    frames::Vector{Int}
    values::Vector{T}
end

@with_kw struct AnimationClip
    tracks::Dict{String, AnimationTrack} = Dict{String, AnimationTrack}()
    fps::Int = 30
    name::String = "default"
end

struct Animation
    clips::Dict{Path, AnimationClip}
    default_framerate::Int
end

Animation(fps::Int=30) = Animation(Dict{Path, AnimationClip}(), fps)


# Based on https://github.com/JuliaLang/BinDeps.jl/blob/69c3fb64f35b5e92c866323ba217e6d4f8f82ae7/src/BinDeps.jl#L84
@static if Compat.Sys.isunix() && Sys.KERNEL != :FreeBSD
    unpack_tarfile(file, directory) = `tar xf $file --directory=$directory`
elseif Sys.KERNEL == :FreeBSD
    function unpack_tarfile(file, directory)
        tar_args = ["--no-same-owner", "--no-same-permissions"]
        pipeline(
            `/bin/mkdir -p $directory`,
            `/usr/bin/tar -xf $file -C $directory $tar_args`)
    end
elseif Compat.Sys.iswindows()
    const exe7z = joinpath(Compat.Sys.BINDIR, "7z.exe")
    unpack_tarfile(file, directory) = `$exe7z x $file -y -o$directory`
else
    unpack_tarfile(args...) = error("I don't know how to unpack tar files on this operating system")
end

function convert_frames_to_video(tar_file_path::AbstractString, output_path::AbstractString="output.mp4"; framerate=60, overwrite=false)
    output_path = abspath(output_path)
    if !isfile(tar_file_path)
        error("Could not find the input file $tar_file_path")
    end
    if isfile(output_path) && !overwrite
        error("The output path $output_path already exists. To overwrite that file, you can pass `overwrite=true` to this function")
    end

    mktempdir() do tmpdir
        run(unpack_tarfile(tar_file_path, tmpdir))
        cmd = `ffmpeg -r $framerate -i %07d.png -vcodec libx264 -preset slow -crf 18`
        if overwrite
            cmd = `$cmd -y`
        end
        cmd = `$cmd $output_path`

        cd(tmpdir) do
            try
                run(cmd)
            catch e
                println("""
Could not call `ffmpeg` to convert your frames into a video.
If you want to convert the frames manually, you can extract the
.tar archive into a directory, cd to that directory, and run:
ffmpeg -r 60 -i %07d.png \\\n\t -vcodec libx264 \\\n\t -preset slow \\\n\t -crf 18 \\\n\t output.mp4""")
                rethrow(e)
            end
        end
    end
    info("Saved output as $output_path")
    return output_path
end
