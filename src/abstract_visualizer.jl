abstract type AbstractVisualizer end

# Interface methods
function setobject! end
function settransform! end
function delete! end
function setprop! end
function setcontrol! end


# Convenient shortcuts for creating new objects
setobject!(vis::AbstractVisualizer, geom::GeometryLike) = setobject!(vis, Object(geom))
setobject!(vis::AbstractVisualizer, geom::GeometryLike, material::AbstractMaterial) = setobject!(vis, Object(geom, material))
