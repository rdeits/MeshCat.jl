# MeshCat.jl: Julia bindings to the MeshCat WebGL viewer

[![Build Status](https://github.com/rdeits/MeshCat.jl/workflows/CI/badge.svg)](https://github.com/rdeits/MeshCat.jl/actions?query=workflow%3ACI)
[![codecov.io](https://codecov.io/github/rdeits/MeshCat.jl/coverage.svg?branch=master)](https://codecov.io/github/rdeits/MeshCat.jl?branch=master)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://rdeits.github.com/MeshCat.jl/dev)

[MeshCat](https://github.com/meshcat-dev/meshcat) is a remotely-controllable 3D viewer, built on top of [three.js](https://threejs.org/). The viewer contains a tree of objects and transformations (i.e. a scene graph) and allows those objects and transformations to be added and manipulated with simple commands. This makes it easy to create 3D visualizations of geometries, mechanisms, and robots. MeshCat.jl runs on macOS, Linux, and Windows.

The MeshCat viewer runs entirely in the browser, with no external dependencies. All files are served locally, so no internet connection is required. Communication between the browser and your Julia code is managed by [HTTP.jl](https://github.com/JuliaWeb/HTTP.jl). That means that MeshCat should work:

* In a normal browser tab
* Inside a Jupyter Notebook with [IJulia.jl](https://github.com/JuliaLang/IJulia.jl)
* In a standalone window with [Electron.jl](https://github.com/davidanthoff/Electron.jl)
* Inside the [Juno IDE](http://junolab.org/)
* Inside the VSCode editor with the [julia-vscode](https://www.julia-vscode.org/) extension.
* In a standalone window with [ElectronDisplay.jl](https://github.com/queryverse/ElectronDisplay.jl)

As much as possible, MeshCat.jl tries to use existing implementations of its fundamental types. In particular, we use:

* Geometric primitives and meshes from [GeometryBasics.jl](https://github.com/JuliaGeometry/GeometryBasics.jl)
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

* [meshcat-python](https://github.com/meshcat-dev/meshcat-python): the Python implementation of the same protocol
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
verts = rand(Point3f, 100_000)
colors = [RGB(p...) for p in verts]
setobject!(vis, PointCloud(verts, colors))
```

![demo-points](https://user-images.githubusercontent.com/591886/36703986-3d18e232-1b2c-11e8-8c40-a73e55cc93b6.png)

### Lines with Configurable Width

Modern browsers don't support the GL_LINEWIDTH parameter, so standard `Line` and `LineBasicMaterial` won't show varying line widths. Use `FatLine` instead for lines with configurable width:

```julia
# Simple fat line with custom width
points = [Point(0, 0, 0), Point(1, 0, 0), Point(1, 1, 0), Point(0, 1, 0)]
setobject!(vis[:thick_line], FatLine(points, FatLineMaterial(linewidth=10.0, color=RGB(1, 0, 0))))

# Fat line with per-vertex colors
points = [Point(i*0.1, sin(i*0.1), cos(i*0.1)) for i in 0:20]
colors = [RGB(i/20, 0, 1-i/20) for i in 0:20]
setobject!(vis[:colored_line],
    FatLine(FatLineGeometry(points, colors),
            FatLineMaterial(linewidth=5.0, vertexColors=true)))

# Dashed fat line
setobject!(vis[:dashed_line],
    FatLine(points,
            FatLineMaterial(linewidth=5.0, color=RGB(1, 1, 0),
                           dashed=true, dashSize=0.1, gapSize=0.05)))

# World-space line width (thickness scales with zoom, false by default uses pixel space)
setobject!(vis[:world_line],
    FatLine(points,
            FatLineMaterial(linewidth=0.02, color=RGB(0, 1, 1), worldUnits=true)))
```

![demo-fat-lines](assets/demo-fat-lines.png)

### Contours

```julia
# Visualize a mesh from the level set of a function
using Meshing: MarchingTetrahedra, isosurface
using GeometryBasics: Mesh, Point, TriangleFace, Vec
xr, yr, zr = ntuple(_ -> LinRange(-1, 1, 50), 3)  # domain for the SDF evaluation
f = x -> sum(sin, 5 * x)
sdf = [f(Vec(x,y,z)) for x in xr, y in yr, z in zr]
vts, fcs = isosurface(sdf, MarchingTetrahedra(), xr, yr, zr)
mesh = Mesh(Point.(vts), TriangleFace.(fcs))
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

# Development

## Local Development with meshcat Viewer

MeshCat.jl serves the viewer from a Julia artifact (defined in `Artifacts.toml`). For local development where you're making changes to both the viewer (JavaScript) and the Julia bindings, you can override this by setting an environment variable:

```bash
export MESHCAT_LOCAL_VIEWER_PATH="/path/to/meshcat/dist"
```

Or set it in Julia before loading the package:

```julia
ENV["MESHCAT_LOCAL_VIEWER_PATH"] = "/path/to/meshcat/dist"
using MeshCat
```

### Development Workflow

1. **Make changes to meshcat viewer**:
   ```bash
   cd /path/to/meshcat
   # Edit src/index.js
   yarn build  # Rebuild dist/main.min.js (exits when done)
   # OR use: yarn watch  # Auto-rebuild on changes (keeps running)
   ```

2. **Test in MeshCat.jl**:
   - Restart Julia REPL (assets are loaded at precompile time)
   - Or force rebuild: `using Pkg; Pkg.build("MeshCat")`
   - Load and test: `using MeshCat; vis = Visualizer(); open(vis)`

3. **Iterate**: Repeat steps 1-2 as needed

Note: The viewer assets (`main.min.js`, `index.html`) are read when the package is loaded, so you must restart Julia or rebuild the package after rebuilding the viewer.

## Updating the Artifact for a New meshcat Release

When you've finished development and pushed changes to the meshcat viewer repository, you need to update `Artifacts.toml` to point to the new version:

1. **Push your meshcat changes and note the commit hash**:
   ```bash
   cd /path/to/meshcat
   git add dist/
   git commit -m "Description of changes"
   git push
   # Note the commit hash, e.g., 2c8a2b897008779cbf877b052526f1e001983270
   ```

2. **Update Artifacts.toml using the helper script**:
   ```bash
   cd /path/to/MeshCat.jl
   julia --project -e 'include("src/artifact_helper.jl"); artifact_helper("COMMIT_HASH")'
   ```

   This will output the new artifact configuration. Copy and paste it into `Artifacts.toml`.

   Note: The `artifact_helper.jl` script requires the `Inflate` package. If not installed, run: `julia --project -e 'import Pkg; Pkg.add("Inflate")'`

3. **Install and test the new artifact**:
   ```bash
   # Unset local viewer override if set
   unset MESHCAT_LOCAL_VIEWER_PATH

   # Clear precompiled cache and install artifact
   rm -rf ~/.julia/compiled/v1.11/MeshCat
   julia --project -e 'using Pkg; Pkg.instantiate()'

   # Test that it works
   julia --project -e 'using MeshCat; vis = Visualizer(); open(vis)'
   ```

4. **Commit the updated Artifacts.toml**:
   ```bash
   git add Artifacts.toml
   git commit -m "Update meshcat artifact to commit COMMIT_HASH"
   ```
