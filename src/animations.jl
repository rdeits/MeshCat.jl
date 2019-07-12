
struct AnimationTrack{T}
    name::String
    jstype::String
    frames::Vector{Int}
    values::Vector{T}
end

function Base.insert!(track::AnimationTrack, frame::Integer, value)
    i = searchsortedfirst(track.frames, frame)
    insert!(track.frames, i, frame)
    insert!(track.values, i, value)
    return track
end

function Base.merge!(a::AnimationTrack, others::AnimationTrack...)
    for other in others
        @assert other.name == a.name
        @assert other.jstype == a.jstype
        for i in eachindex(other.frames, other.values)
            # TODO: improve performance.
            insert!(a, other.frames[i], other.values[i])
        end
    end
    return a
end

@with_kw struct AnimationClip
    tracks::Dict{String, AnimationTrack} = Dict{String, AnimationTrack}()
    fps::Int = 30
    name::String = "default"
end

function Base.merge!(a::AnimationClip, others::AnimationClip...)
    for other in others
        @assert other.fps == a.fps
        merge!(merge!, a.tracks, other.tracks) # merge tracks recursively
    end
    return a
end

struct Animation
    clips::Dict{Path, AnimationClip}
    default_framerate::Int
end

Animation(fps::Int=30) = Animation(Dict{Path, AnimationClip}(), fps)

function Base.merge!(a::Animation, others::Animation...)
    for other in others
        # @assert a.default_framerate == other.default_framerate
        merge!(merge!, a.clips, other.clips) # merge clips recursively
    end
    return a
end

Base.merge(a::Animation, others::Animation...) = merge!(Animation(), a, others...)

function convert_frames_to_video(tar_file_path::AbstractString, output_path::AbstractString="output.mp4"; framerate=60, overwrite=false)
    output_path = abspath(output_path)
    if !isfile(tar_file_path)
        error("Could not find the input file $tar_file_path")
    end
    if isfile(output_path) && !overwrite
        error("The output path $output_path already exists. To overwrite that file, you can pass `overwrite=true` to this function")
    end

    mktempdir() do tmpdir
        run(unpack_cmd(tar_file_path, tmpdir, ".tar", nothing))
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
    @info("Saved output as $output_path")
    return output_path
end
