# MeshCat.jl: Julia bindings to the MeshCat WebGL viewer

[![Build Status](https://github.com/rdeits/MeshCat.jl/workflows/CI/badge.svg)](https://github.com/rdeits/MeshCat.jl/actions?query=workflow%3ACI)
[![codecov.io](https://codecov.io/github/rdeits/MeshCat.jl/coverage.svg?branch=master)](https://codecov.io/github/rdeits/MeshCat.jl?branch=master)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://rdeits.github.com/MeshCat.jl/dev)

[MeshCat](https://github.com/rdeits/meshcat) is a remotely-controllable 3D viewer, built on top of [three.js](https://threejs.org/). The viewer contains a tree of objects and transformations (i.e. a scene graph) and allows those objects and transformations to be added and manipulated with simple commands. This makes it easy to create 3D visualizations of geometries, mechanisms, and robots. MeshCat.jl runs on macOS, Linux, and Windows.

The MeshCat viewer runs entirely in the browser, with no external dependencies. All files are served locally, so no internet connection is required. Communication between the browser and your Julia code is managed by [HTTP.jl](https://github.com/JuliaWeb/HTTP.jl). That means that MeshCat should work:

* In a normal browser tab
* Inside a Jupyter Notebook with [IJulia.jl](https://github.com/JuliaLang/IJulia.jl)
* In a standalone window with [Blink.jl](https://github.com/JunoLab/Blink.jl)
* Inside the [Juno IDE](http://junolab.org/)
* Inside the VSCode editor with the [julia-vscode](https://www.julia-vscode.org/) extension.
* In a standalone window with [ElectronDisplay.jl](https://github.com/queryverse/ElectronDisplay.jl)

As much as possible, MeshCat.jl tries to use existing implementations of its fundamental types. In particular, we use:

* Geometric primitives and meshes from [GeometryTypes.jl](https://github.com/JuliaGeometry/GeometryTypes.jl)
* Colors from [ColorTypes.jl](https://github.com/JuliaGraphics/ColorTypes.jl)
* Affine transformations from [CoordinateTransformations.jl](https://github.com/FugroRoames/CoordinateTransformations.jl/)

That means that MeshCat should play well with other tools in the JuliaGeometry ecosystem like MeshIO.jl, Meshing.jl, etc.

# Demos

## Basic Usage

For detailed examples of usage, check out [demo.ipynb](notebooks/demo.ipynb).

## Animation

To learn about the animation system (introduced in MeshCat.jl v0.2.0), see [animation.ipynb](notebooks/animation.ipynb).

# Related Projects

MeshCat.jl is a successor to [DrakeVisualizer.jl](https://github.com/rdeits/DrakeVisualizer.jl), and the interface is quite similar (with the exception that we use `setobject!` instead of `setgeometry!`). The primary difference is that DrakeVisualizer required Director, LCM, and VTK, all of which could be difficult to install, while MeshCat just needs a web browser. MeshCat also has better support for materials, textures, point clouds, and complex meshes.

You may also want to check out:

* [meshcat-python](https://github.com/rdeits/meshcat-python): the Python implementation of the same protocol
* [MeshCatMechanisms.jl](https://github.com/rdeits/MeshCatMechanisms.jl) extensions to MeshCat.jl for visualizing mechanisms, robots, and URDFs

# Examples

### Create a visualizer and open it

```julia
using MeshCat
vis = Visualizer()
open(vis)

## In an IJulia/Jupyter notebook, you can also do:
# IJuliaCell(vis)
```

### Cube

```julia
using GeometryBasics
using CoordinateTransformations

setobject!(vis, HyperRectangle(Vec(0., 0, 0), Vec(1., 1, 1)))
settransform!(vis, Translation(-0.5, -0.5, 0))
```

![demo-cube](https://user-images.githubusercontent.com/591886/36703848-9da5abae-1b2b-11e8-8fa7-57e5cd3e2420.png)

### Point Clouds

```julia
using ColorTypes
verts = rand(Point3f0, 100_000)
colors = [RGB(p...) for p in verts]
setobject!(vis, PointCloud(verts, colors))
```

![demo-points](https://user-images.githubusercontent.com/591886/36703986-3d18e232-1b2c-11e8-8c40-a73e55cc93b6.png)

### Contours

```julia
# Visualize a mesh from the level set of a function
using Meshing
f = x -> sum(sin, 5 * x)
sdf = SignedDistanceField(f, HyperRectangle(Vec(-1, -1, -1), Vec(2, 2, 2)))
mesh = HomogenousMesh(sdf, MarchingTetrahedra())
setobject!(vis, mesh,
           MeshPhongMaterial(color=RGBA{Float32}(1, 0, 0, 0.5)))
```

![demo-contour](https://user-images.githubusercontent.com/591886/36703981-37b62ba6-1b2c-11e8-90aa-4c38486732e7.png)

### Polyhedra

See [here](https://github.com/JuliaPolyhedra/Polyhedra.jl/blob/master/examples/3D%20Plotting%20a%20projection%20of%20the%204D%20permutahedron.ipynb)
for a notebook with the example.

```julia
# Visualize the permutahedron of order 4 using Polyhedra.jl
using Combinatorics, Polyhedra
v = vrep(collect(permutations([0, 1, 2, 3])))
using CDDLib
p4 = polyhedron(v, CDDLib.Library())

# Project that polyhedron down to 3 dimensions for visualization
v1 = [1, -1,  0,  0]
v2 = [1,  1, -2,  0]
v3 = [1,  1,  1, -3]
p3 = project(p4, [v1 v2 v3])

# Show the result
setobject!(vis, Polyhedra.Mesh(p3))
```

![polyhedron](https://user-images.githubusercontent.com/591886/37313984-fa3b20c2-2627-11e8-8238-71607a7f16e7.png)

### Mechanisms

Using https://github.com/rdeits/MeshCatMechanisms.jl

![demo-valkyrie](https://user-images.githubusercontent.com/591886/36703991-41b6991a-1b2c-11e8-8804-24c56ddd94cc.png)

