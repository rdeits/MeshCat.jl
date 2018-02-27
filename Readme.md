# MeshCat.jl: Julia bindings to the MeshCat WebGL viewer

[![Build Status](https://travis-ci.org/rdeits/MeshCat.jl.svg?branch=master)](https://travis-ci.org/rdeits/MeshCat.jl)
[![codecov.io](https://codecov.io/github/rdeits/MeshCat.jl/coverage.svg?branch=master)](https://codecov.io/github/rdeits/MeshCat.jl?branch=master)

[MeshCat](https://github.com/rdeits/meshcat) is a remotely-controllable 3D viewer, built on top of [three.js](https://threejs.org/). The viewer contains a tree of objects and transformations (i.e. a scene graph) and allows those objects and transformations to be added and manipulated with simple commands. This makes it easy to create 3D visualizations of geometries, mechanisms, and robots. 

The MeshCat architecture is based on the model used by [Jupyter](http://jupyter.org/)

- The viewer itself runs entirely in the browser, with no external dependencies. All files are served locally, so no internet connection is required. 
- The MeshCat server communicates with the viewer via WebSockets
- Your code can use the MeshCat.jl Julia library or communicate directly with the server through its [ZeroMQ](http://zguide.zeromq.org/) socket. 

# Usage

See [demo.ipynb](demo.ipynb)

# Examples

### Cube

![demo-cube](https://user-images.githubusercontent.com/591886/36703848-9da5abae-1b2b-11e8-8fa7-57e5cd3e2420.png)

### Complex Geometries

![demo-contour](https://user-images.githubusercontent.com/591886/36703981-37b62ba6-1b2c-11e8-90aa-4c38486732e7.png)

### Point Clouds

![demo-points](https://user-images.githubusercontent.com/591886/36703986-3d18e232-1b2c-11e8-8c40-a73e55cc93b6.png)

### Mechanisms

Using https://github.com/rdeits/MeshCatMechanisms.jl

![demo-valkyrie](https://user-images.githubusercontent.com/591886/36703991-41b6991a-1b2c-11e8-8804-24c56ddd94cc.png)

