abstract type AbstractCommand end

struct SetObject{O <: AbstractObject} <: AbstractCommand
    object::O
    path::Path
end

struct SetTransform{T <: Transformation} <: AbstractCommand
    tform::T
    path::Path
end

struct Delete <: AbstractCommand
    path::Path
end

struct SetProperty{T} <: AbstractCommand
    path::Path
    property::String
    value::T
end

abstract type AbstractControl end

struct Button <: AbstractControl
    observer::Observable
    name::String
end

struct NumericControl{T} <: AbstractControl
    observer::Observable
    name::String
    value::T
    min::T
    max::T
end

struct SetControl <: AbstractCommand
    control::AbstractControl
end

struct SetAnimation{A <: Animation} <: AbstractCommand
    animation::A
    play::Bool
    repetitions::Int
end

SetAnimation(anim::Animation; play=true, repetitions=1) = SetAnimation(anim, play, repetitions)

