wider_js_type(::Type{<:Integer}) = Float64  # Javascript thinks everything is a `double`
wider_js_type(::Type{Float64}) = Float64
wider_js_type(::Type{Bool}) = Bool
wider_js_type(x) = x

const DEFAULT_PROPERTY_TYPES = Dict{String, String}(
    "scale" => "vector3",
    "position" => "vector3",
    "quaternion" => "quaternion",
    "visible" => "bool",
)

function get_property_type(property_name::AbstractString)
    get(DEFAULT_PROPERTY_TYPES, property_name, "number")
end

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
js_quaternion(q::QuatRotation) = [q.q.v1, q.q.v2, q.q.v3, q.q.s]
js_quaternion(::UniformScaling) = js_quaternion(QuatRotation(1., 0., 0., 0.))
js_quaternion(r::Rotation) = js_quaternion(QuatRotation(r))
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
    _setprop!(clip, frame, prop, get_property_type(prop), value)
end

function Cassette.overdub(ctx::AnimationCtx, ::typeof(setprop!), vis::Visualizer, prop::AbstractString, jstype::AbstractString, value)
    animation, frame = ctx.metadata
    clip = getclip!(animation, vis.path)
    _setprop!(clip, frame, prop, jstype, value)
end

"""
Call the given function `f`, but intercept any `settransform!` or `setprop!` calls
and apply them to the given animation at the given frame instead.

$(TYPEDSIGNATURES)

Usage:

```
vis = Visualizer()
setobject!(vis[:cube], Rect(Vec(0.0, 0.0, 0.0), Vec(0.5, 0.5, 0.5)))

anim = Animation()

# At frame 0, set the cube's position to be the origin
atframe(anim, 0) do
    settransform!(vis[:cube], Translation(0.0, 0.0, 0.0))
end

# At frame 30, set the cube's position to be [1, 0, 0]
atframe(anim, 30) do
    settransform!(vis[:cube], Translation(1.0, 0.0, 0.0))
end

setanimation!(vis, anim)
```
"""
function atframe(f, animation::Animation, frame::Integer)
    Cassette.overdub(AnimationCtx(metadata=(animation, frame)), f)
    return animation
end
