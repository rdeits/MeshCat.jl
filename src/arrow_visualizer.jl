struct ArrowVisualizer{V<:AbstractVisualizer}
    vis::V
end

function setobject!(vis::ArrowVisualizer, material::AbstractMaterial=defaultmaterial();
        shaft_material::AbstractMaterial=material,
        head_material::AbstractMaterial=material)
    settransform!(vis, zero(Point{3, Float64}), zero(Vec{3, Float64}))
    shaft = Cylinder(zero(Point{3, Float64}), Point(0.0, 0.0, 1.0), 1.0)
    setobject!(vis.vis[:shaft], shaft, shaft_material)
    head = Cone(zero(Point{3, Float64}), Point(0.0, 0.0, 1.0), 1.0)
    setobject!(vis.vis[:head], head, head_material)
    vis
end

function Base.show(io::IO, v::ArrowVisualizer)
    print(io, "MeshCat ArrowVisualizer with path $(v.vis.path)/arrow")
end

function settransform!(vis::ArrowVisualizer, base::Point{3}, vec::Vec{3};
        shaft_radius=0.01,
        max_head_radius=2*shaft_radius,
        max_head_length=max_head_radius)
    vec_length = norm(vec)
    rotation = if vec_length > eps(typeof(vec_length))
        rotation_between(SVector(0., 0., 1.), vec)
    else
        one(Quat{Float64})
    end |> LinearMap

    shaft_length = max(vec_length - max_head_length, 0)
    shaft_scaling = LinearMap(Diagonal(SVector(shaft_radius, shaft_radius, shaft_length)))
    shaft_tform = Translation(base) ∘ rotation ∘ shaft_scaling
    settransform!(vis.vis, shaft_tform)

    if vec_length > eps(typeof(vec_length))
        head_length = vec_length - shaft_length
        head_radius = max_head_radius * head_length / max_head_length
        head_scaling = LinearMap(Diagonal(SVector(head_radius, head_radius, head_length)))
        head_tform = inv(shaft_scaling) ∘ Translation(shaft_length * Vec(0, 0, 1)) ∘ head_scaling
        # head_tform = Translation(base) ∘ rotation ∘ Translation(shaft_length * Vec(0, 0, 1)) ∘ head_scaling
        settransform!(vis.vis[:head], head_tform)
    end

    vis
end

function settransform!(vis::ArrowVisualizer, base::Point{3}, tip::Point{3}; kwargs...)
    settransform!(vis, base, Vec(tip - base))
end
