struct ArrowVisualizer{V<:AbstractVisualizer}
    shaft_vis::V
    head_vis::V
end

ArrowVisualizer(vis::AbstractVisualizer) = ArrowVisualizer(vis[:shaft], vis[:head])

function setobject!(vis::ArrowVisualizer, material::AbstractMaterial=defaultmaterial();
        shaft_material::AbstractMaterial=material,
        head_material::AbstractMaterial=material)
    settransform!(vis, zero(Point{3, Float64}), zero(Vec{3, Float64}))
    shaft = Cylinder(zero(Point{3, Float64}), Point(0.0, 0.0, 1.0), 1.0)
    setobject!(vis.shaft_vis, shaft, shaft_material)
    head = Cone(zero(Point{3, Float64}), Point(0.0, 0.0, 1.0), 1.0)
    setobject!(vis.head_vis, head, head_material)
    vis
end

function Base.show(io::IO, v::ArrowVisualizer)
    print(io, "MeshCat ArrowVisualizer with paths $(v.shaft_vis.path) and $(v.head_vis.path).")
end

function settransform!(vis::ArrowVisualizer, base::Point{3}, vec::Vec{3};
        shaft_radius=0.01,
        max_head_radius=2*shaft_radius,
        max_head_length=max_head_radius)
    vec_length = norm(vec)
    rotation = if vec_length > eps(typeof(vec_length))
        rotation_between(SVector(0., 0., 1.), vec)
    else
        one(RotMatrix3{Float64})
    end |> LinearMap

    shaft_length = max(vec_length - max_head_length, 0)
    shaft_scaling = LinearMap(Diagonal(SVector(shaft_radius, shaft_radius, shaft_length)))
    shaft_tform = Translation(base) ∘ rotation ∘ shaft_scaling
    settransform!(vis.shaft_vis, shaft_tform)

    head_length = vec_length - shaft_length
    head_radius = max_head_radius * head_length / max_head_length
    head_scaling = LinearMap(Diagonal(SVector(head_radius, head_radius, head_length)))
    head_tform = Translation(base) ∘ rotation ∘ Translation(shaft_length * Vec(0, 0, 1)) ∘ head_scaling
    settransform!(vis.head_vis, head_tform)

    vis
end

function settransform!(vis::ArrowVisualizer, base::Point{3}, tip::Point{3}; kwargs...)
    settransform!(vis, base, Vec(tip - base))
end
