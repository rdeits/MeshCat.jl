# MeshCat.jl: Julia bindings to the MeshCat WebGL viewer

[![Build Status](https://travis-ci.org/rdeits/MeshCat.jl.svg?branch=master)](https://travis-ci.org/rdeits/MeshCat.jl)
[![codecov.io](https://codecov.io/github/rdeits/MeshCat.jl/coverage.svg?branch=master)](https://codecov.io/github/rdeits/MeshCat.jl?branch=master)

[MeshCat](https://github.com/rdeits/meshcat) is a remotely-controllable 3D viewer, built on top of [three.js](https://threejs.org/). The MeshCat viewer runs in a browser and listens for geometry commands over WebSockets. This makes it easy to create a tree of objects and transformations by sending the appropriate commands over the websocket.

This package, MeshCat.jl, allows you to create objects and move them in space from Julia. For some examples of usage, see `demo.ipynb`.
