wider_js_type(::Type{<:Integer}) = Float64  # Javascript thinks everything is a `double`
wider_js_type(::Type{Float64}) = Float64
wider_js_type(x) = x

function _setprop!(clip::AnimationClip, frame::Integer, prop::AbstractString, jstype::AbstractString, value)
    T = wider_js_type(typeof(value))
    track = get!(clip.tracks, prop) do
        AnimationTrack{T}(prop, jstype)
    end
    insert!(track, frame, value)
    return nothing
end

function getclip!(animation::Animation, path::Path)
    get!(animation.clips, path) do
        AnimationClip(fps=animation.default_framerate)
    end
end

js_quaternion(m::AbstractMatrix) = js_quaternion(RotMatrix(SMatrix{3, 3, eltype(m)}(m)))
js_quaternion(q::Quat) = [q.x, q.y, q.z, q.w]
js_quaternion(::UniformScaling) = js_quaternion(Quat(1., 0., 0., 0.))
js_quaternion(r::Rotation) = js_quaternion(Quat(r))
js_quaternion(tform::Transformation) = js_quaternion(transform_deriv(tform, SVector(0., 0, 0)))

function js_scaling(tform::AbstractAffineMap)
    m = transform_deriv(tform, SVector(0., 0, 0))
    SVector(norm(SVector(m[1, 1], m[2, 1], m[3, 1])),
            norm(SVector(m[1, 2], m[2, 2], m[3, 2])),
            norm(SVector(m[1, 3], m[2, 3], m[3, 3])))
end

js_position(t::Transformation) = convert(Vector, t(SVector(0., 0, 0)))

Cassette.@context AnimationCtx

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

function atframe(f::Function, anim::Animation, path::Path, frame::Integer)
    error("""
    atframe(f::Function, anim::Animation, path::Path, frame::Integer) is no longer supported.
    Please see the updated animation example notebook.
    """)
end

function atframe(f::Function, anim::Animation, vis::Visualizer, frame::Integer)
    Base.depwarn("""
    atframe(f::Function, anim::Animation, vis::Visualizer, frame::Integer) is deprecated.
    Please use atframe(g, anim, frame) instead, where g is similar to f but takes
    no arguments and should call methods on vis.
    See also the updated animation example notebook.
    """, :atframe)
    atframe(() -> f(vis), anim, frame)
end
