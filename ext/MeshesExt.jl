module MeshesExt

using MeshCat
using GeometryBasics
import Meshes

# Helper function 
function extract_coords(pt::Meshes.Point)
    #  to(pt) gets the vector, Tuple() gets the numbers
    tup = Tuple(Meshes.to(pt))
    # Dividing by oneunit to safely strip the 'm' (meters) unit away
    return map(x -> Float64(x / oneunit(x)), tup)
end

# Opening the door for Meshes.jl types to enter setobject!
function MeshCat.setobject!(vis::MeshCat.AbstractVisualizer, geom::Meshes.Geometry, material::MeshCat.AbstractMaterial=MeshCat.defaultmaterial())
    MeshCat.setobject!(vis, MeshCat.Object(geom, material))
end

# Translating Meshes.Box -> GeometryBasics.HyperRectangle
function MeshCat.Object(box::Meshes.Box, material::MeshCat.AbstractMaterial=MeshCat.defaultmaterial())
    min_pt, max_pt = Meshes.extrema(box)
    
    cmin = extract_coords(min_pt)
    cmax = extract_coords(max_pt)
    
    # GeometryBasics uses a starting point and the width/height/depth
    widths = cmax .- cmin
    
    gb_box = GeometryBasics.HyperRectangle(
        GeometryBasics.Point(cmin...), 
        GeometryBasics.Point(widths...)
    )
    
    return MeshCat.Object(gb_box, material)
end

# Translating Meshes.Sphere -> GeometryBasics.HyperSphere
function MeshCat.Object(sphere::Meshes.Sphere, material::MeshCat.AbstractMaterial=MeshCat.defaultmaterial())
    center = extract_coords(Meshes.center(sphere))
    
    # The radius also has units, so we must strip them
    r = Meshes.radius(sphere)
    r_val = Float64(r / oneunit(r))
    
    gb_sphere = GeometryBasics.HyperSphere(GeometryBasics.Point(center...), r_val)
    
    return MeshCat.Object(gb_sphere, material)
end

end