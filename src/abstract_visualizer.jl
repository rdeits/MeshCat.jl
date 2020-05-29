"""
Abstract parent type of `MeshCat.Visualizer`.
"""
abstract type AbstractVisualizer end

# Interface methods
function setobject! end
function settransform! end
function delete! end
function setprop! end
function setcontrol! end


# Convenient shortcuts
"""
$(TYPEDSIGNATURES)

This will construct an appropriate three.js object from the given geometry and
a default material.
"""
setobject!(vis::AbstractVisualizer, geom::GeometryLike) = setobject!(vis, Object(geom))

"""
$(TYPEDSIGNATURES)

This will construct an appropriate three.js object from the given geometry and
the given material.
"""
setobject!(vis::AbstractVisualizer, geom::GeometryLike, material::AbstractMaterial) = setobject!(vis, Object(geom, material))

"""
Toggle visibility of the visualizer at the current path.

$(TYPEDSIGNATURES)
"""
setvisible!(vis::AbstractVisualizer, visible::Bool) = setprop!(vis, "visible", visible)
