abstract type AbstractVisualizer end

# Interface methods
function setobject! end
function settransform! end
function delete! end
function setprop! end
function setcontrol! end


# Convenient shortcuts
setobject!(vis::AbstractVisualizer, geom::GeometryLike) = setobject!(vis, Object(geom))
setobject!(vis::AbstractVisualizer, geom::GeometryLike, material::AbstractMaterial) = setobject!(vis, Object(geom, material))
setvisible!(vis::AbstractVisualizer, visible::Bool) = setprop!(vis, "visible", visible)
