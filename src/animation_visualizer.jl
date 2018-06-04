struct AnimationFrameVisualizer <: AbstractVisualizer
    animation::Animation
    path::Path
    current_frame::Int
end

function _setprop!(track::AnimationTrack, frame::Integer, value)
    i = searchsortedfirst(track.frames, frame)
    insert!(track.frames, i, frame)
    insert!(track.values, i, value)
end

function _setprop!(clip::AnimationClip, frame::Integer, prop::AbstractString, jstype::AbstractString, value)
    track = get!(clip.tracks, prop) do
        AnimationTrack(prop, jstype, Int[], typeof(value)[])
    end
    _setprop!(track, frame, value)
end

function getclip!(vis::AnimationFrameVisualizer)
    clip = get!(vis.animation.clips, vis.path) do
        AnimationClip(fps=vis.animation.default_framerate)
    end
end


js_quaternion(q::Quat) = [q.x, q.y, q.z, q.w]
js_quaternion(::UniformScaling) = js_quaternion(Quat(1., 0., 0., 0.))
js_quaternion(r::Rotation) = js_quaternion(Quat(r))
js_quaternion(tform::Transformation) = js_quaternion(transform_deriv(tform, SVector(0., 0, 0)))

js_position(t::Transformation) = convert(Vector, t(SVector(0., 0, 0)))

function settransform!(vis::AnimationFrameVisualizer, tform::Transformation)
    clip = getclip!(vis)
    _setprop!(clip, vis.current_frame, "position", "vector3", js_position(tform))
    _setprop!(clip, vis.current_frame, "quaternion", "quaternion", js_quaternion(tform))
end

function setprop!(vis::AnimationFrameVisualizer, prop::AbstractString, value)
    clip = getclip!(vis)
    _setprop!(clip, vis.current_frame, prop, value)
end

function setprop!(vis::AnimationFrameVisualizer, prop::AbstractString, jstype::AbstractString, value)
    clip = getclip!(vis)
    _setprop!(clip, vis.current_frame, prop, value)
end

function atframe(f::Function, anim::Animation, path::Path, frame::Integer)
    anim_vis = AnimationFrameVisualizer(anim, path, frame)
    f(anim_vis)
end

atframe(f::Function, anim::Animation, vis::Visualizer, frame::Integer) =
    atframe(f, anim, vis.path, frame)

Base.getindex(vis::AnimationFrameVisualizer, path::Union{Symbol, AbstractString}...) = AnimationFrameVisualizer(vis.animation, vcat(vis.path, path...), vis.current_frame)
