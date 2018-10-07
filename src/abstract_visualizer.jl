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

function MeshCat.setobject!(vis::AbstractVisualizer, geom::HomogenousMesh)
    if geom.color == nothing
        return setobject!(vis, Object(geom))
    else
        return setobject!(vis, Object(geom, MeshLambertMaterial(color=geom.color)))
    end
end
