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

wider_js_type(::Type{<:Integer}) = Float64  # Javascript thinks everything is a `double`
wider_js_type(::Type{Float64}) = Float64
wider_js_type(x) = x

function _setprop!(clip::AnimationClip, frame::Integer, prop::AbstractString, jstype::AbstractString, value)
    track = get!(clip.tracks, prop) do
        AnimationTrack(prop, jstype, Int[], wider_js_type(typeof(value))[])
    end
    _setprop!(track, frame, value)
end

function getclip!(vis::AnimationFrameVisualizer)
    clip = get!(vis.animation.clips, vis.path) do
        AnimationClip(fps=vis.animation.default_framerate)
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

function settransform!(vis::AnimationFrameVisualizer, tform::Transformation)
    clip = getclip!(vis)
    _setprop!(clip, vis.current_frame, "scale", "vector3", js_scaling(tform))
    _setprop!(clip, vis.current_frame, "position", "vector3", js_position(tform))
    _setprop!(clip, vis.current_frame, "quaternion", "quaternion", js_quaternion(tform))
end

function setprop!(vis::AnimationFrameVisualizer, prop::AbstractString, value)
    clip = getclip!(vis)
    _setprop!(clip, vis.current_frame, prop, "number", value)
end

function setprop!(vis::AnimationFrameVisualizer, prop::AbstractString, jstype::AbstractString, value)
    clip = getclip!(vis)
    _setprop!(clip, vis.current_frame, prop, jstype, value)
end

function atframe(f::Function, anim::Animation, path::Path, frame::Integer)
    anim_vis = AnimationFrameVisualizer(anim, path, frame)
    f(anim_vis)
end

atframe(f::Function, anim::Animation, vis::Visualizer, frame::Integer) =
    atframe(f, anim, vis.path, frame)

Base.getindex(vis::AnimationFrameVisualizer, path...) = AnimationFrameVisualizer(vis.animation, joinpath(vis.path, path...), vis.current_frame)
