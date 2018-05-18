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
