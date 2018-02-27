# MeshCat.jl: Julia bindings to the MeshCat WebGL viewer

[![Build Status](https://travis-ci.org/rdeits/MeshCat.jl.svg?branch=master)](https://travis-ci.org/rdeits/MeshCat.jl)
[![codecov.io](https://codecov.io/github/rdeits/MeshCat.jl/coverage.svg?branch=master)](https://codecov.io/github/rdeits/MeshCat.jl?branch=master)

[MeshCat](https://github.com/rdeits/meshcat) is a remotely-controllable 3D viewer, built on top of [three.js](https://threejs.org/). The viewer contains a tree of objects and transformations (i.e. a scene graph) and allows those objects and transformations to be added and manipulated with simple commands. This makes it easy to create 3D visualizations of geometries, mechanisms, and robots. 

The MeshCat architecture is based on the model used by [Jupyter](http://jupyter.org/)

- The viewer itself runs entirely in the browser, with no external dependencies. All files are served locally, so no internet connection is required. 
- The MeshCat server communicates with the viewer via WebSockets
- Your code can use the MeshCat.jl Julia library or communicate directly with the server through its [ZeroMQ](http://zguide.zeromq.org/) socket. 

As much as possible, MeshCat.jl tries to use existing implementations of its fundamental types. In particular, we use:

* Geometric primitives and meshes from [GeometryTypes.jl](https://github.com/JuliaGeometry/GeometryTypes.jl)
* Colors from [ColorTypes.jl](https://github.com/JuliaGraphics/ColorTypes.jl)
* Affine transformations from [CoordinateTransformations.jl](https://github.com/FugroRoames/CoordinateTransformations.jl/)

That means that MeshCat should play well with other tools in the JuliaGeometry ecosystem like MeshIO.jl, Meshing.jl, etc. 

# Usage

See [demo.ipynb](demo.ipynb)

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
using GeometryTypes
using CoordinateTransformations

setobject!(vis, HyperRectangle(Vec(0., 0, 0), Vec(1., 1, 1)))
settransform!(vis, Translation(-0.5, -0.5, 0))```
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

### Complex Geometries

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

### Mechanisms

Using https://github.com/rdeits/MeshCatMechanisms.jl

![demo-valkyrie](https://user-images.githubusercontent.com/591886/36703991-41b6991a-1b2c-11e8-8804-24c56ddd94cc.png)

