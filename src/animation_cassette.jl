using Cassette

Cassette.@context AnimationCtx

function getclip!(animation::Animation, path::Path)
    get!(animation.clips, path) do
        AnimationClip(fps=animation.default_framerate)
    end
end

function Cassette.overdub(ctx::AnimationCtx, ::typeof(settransform!), vis::Visualizer, tform::Transformation)
    animation, frame = ctx.metadata
    clip = getclip!(animation, vis.path)
    _setprop!(clip, frame, "scale", "vector3", js_scaling(tform))
    _setprop!(clip, frame, "position", "vector3", js_position(tform))
    _setprop!(clip, frame, "quaternion", "quaternion", js_quaternion(tform))
end

function Cassette.overdub(ctx::AnimationCtx, ::typeof(setprop!), vis::Visualizer, prop::AbstractString, value)
    animation, frame = ctx.metadata
    clip = getclip!(animation, vis.path)
    _setprop!(clip, frame, prop, "number", value)
end

function Cassette.overdub(ctx::AnimationCtx, ::typeof(setprop!), vis::Visualizer, prop::AbstractString, jstype::AbstractString, value)
    animation, frame = ctx.metadata
    clip = getclip!(animation, vis.path)
    _setprop!(clip, frame, prop, jstype, value)
end

function atframe(f, animation::Animation, frame::Integer)
    Cassette.overdub(AnimationCtx(metadata=(animation, frame)), f)
    return animation
end
