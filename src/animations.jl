abstract type AbstractAnimationTrack end

struct TransformTrack <: AbstractAnimationTrack
    frames::Vector{Pair{Int, AffineMap{RotMatrix{3, Float64, 9}, Translation{SVector{3, Float64}}}}}
end

function lower(track::TransformTrack)
    times = first.(track.frames)
    positions = [tform.v.v for (time, tform) in track.frames]
    position_track = Dict{String, Any}(
        "name" => ".position",
        "type" => "vector3",
        "keys" => [
            Dict{String, Any}(
                "time" => times[i],
                "value" => collect(positions[i])
            ) for i in eachindex(times)]
    )

    quaternions = [Quat(tform.m) for (time, tform) in track.frames]
    quat_track = Dict{String, Any}(
        "name" => ".rotation",
        "type" => "quaternion",
        "keys" => [
            Dict{String, Any}(
                "time" => times[i],
                "value" => lower(quaternions[i])
            ) for i in eachindex(times)]
    )
    [position_track, quat_track]
end

@with_kw struct AnimationClip{T <: AbstractAnimationTrack}
    tracks::Vector{T}
    fps::Int = 30
    name::String = "default"
end

function lower(clip::AnimationClip)
    Dict{String, Any}(
        "fps" => clip.fps,
        "name" => clip.name,
        "tracks" => vcat(lower.(clip.tracks)...)
    )
end

struct Animation{C <: AnimationClip}
    animations::Vector{Pair{Path, C}}
end

function lower(a::Animation)
    [Dict{String, Any}(
        "path" => lower(path),
        "clip" => lower(clip)
    ) for (path, clip) in a.animations]
end

struct SetAnimation{A <: Animation} <: AbstractCommand
    animation::A
    play::Bool
    repetitions::Int
end

SetAnimation(anim::Animation; play=true, repetitions=1) = SetAnimation(anim, play, repetitions)

function lower(cmd::SetAnimation)
    Dict{String, Any}(
        "type" => "set_animation",
        "animations" => lower(cmd.animation),
        "options" => Dict{String, Any}(
            "play" => cmd.play,
            "repetitions" => cmd.repetitions
        )
    )
end
