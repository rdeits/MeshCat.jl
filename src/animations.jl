struct AnimationTrack{T}
    name::String
    jstype::String
    events::Vector{Pair{Int, T}} # frame => value
end

AnimationTrack{T}(name::String, jstype::String) where {T} = AnimationTrack(name, jstype, Pair{Int, T}[])

function Base.insert!(track::AnimationTrack, frame::Integer, value)
    i = searchsortedfirst(track.events, frame; by=first)
    if i <= length(track.events) && first(track.events[i]) == frame
        track.events[i] = frame => value
    else
        insert!(track.events, i, frame => value)
    end
    return track
end

function Base.merge!(a::AnimationTrack{T}, others::AnimationTrack{T}...) where T
    l = length(a.events)
    for other in others
        @assert other.name == a.name
        @assert other.jstype == a.jstype
        l += length(other.events)
    end
    events = similar(a.events, l)
    mergesorted!(events, a.events, Iterators.flatten((other.events for other in others)))
    combine!(events, by=first, combine=(a, b) -> b)
    resize!(a.events, length(events))
    copyto!(a.events, events)
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
    visualizer::CoreVisualizer
    default_framerate::Int
    clips::Dict{Path, AnimationClip}

    """
    Create a new animation. See [`atframe`](@ref) to adjust object poses or properties
    in that animation.

    $(TYPEDSIGNATURES)
    """
    Animation(visualizer::CoreVisualizer; fps=30) = new(visualizer, fps, Dict())
end


"""
Merge multiple animations, storing the result in `a`.

$(TYPEDSIGNATURES)
"""
function Base.merge!(a::Animation, others::Animation...)
    for other in others
        @assert a.visualizer === other.visualizer
        @assert a.default_framerate == other.default_framerate
        merge!(merge!, a.clips, other.clips) # merge clips recursively
    end
    return a
end

"""
Merge two or more animations, returning a new animation.

$(TYPEDSIGNATURES)

The animations may involve the same properties or different properties
(animations of the same property on the same path will have their events
interleaved). All animations must have the same framerate.
"""
Base.merge(a::Animation, others::Animation...) = merge!(Animation(a.visualizer; fps=a.default_framerate), a, others...)

"""
Convert the `.tar` file of still images produced by the meshcat "record" feature
into a video.

$(TYPEDSIGNATURES)

To record an animation which has been played in the meshcat visualizer, click
"Open Controls", then navigate to the "Animations" folder and click "record".
This will step through the animation frame-by-frame and then prompt you to
download a `.tar` file containing the resulting frames. You can then pass the
path to that `.tar` file to this function to produce a video.
You can pass additional arguments for the video conversion, for 
example, `conversion_args=("-pix_fmt", "yuv420p")` to create videos playable in 
Windows.

This uses FFMPEG.jl internally, so you do *not* need to have installed ffmpeg
manually.
"""
function convert_frames_to_video(tar_file_path::AbstractString, output_path::AbstractString="output.mp4"; framerate=60, overwrite=false, conversion_args=())
    output_path = abspath(output_path)
    if !isfile(tar_file_path)
        error("Could not find the input file $tar_file_path")
    end
    if isfile(output_path) && !overwrite
        error("The output path $output_path already exists. To overwrite that file, you can pass `overwrite=true` to this function")
    end

    mktempdir() do tmpdir
        Tar.extract(tar_file_path, tmpdir)
        cmd = ["-r", string(framerate), "-i", "%07d.png", "-vcodec", "libx264", "-preset", "slow", "-crf", "18", conversion_args...]
        if overwrite
            push!(cmd, "-y")
        end
        push!(cmd, output_path)

        cd(tmpdir) do
            FFMPEG.exe(cmd...)
        end
    end
    @info("Saved output as $output_path")
    return output_path
end
