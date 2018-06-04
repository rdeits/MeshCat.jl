
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

