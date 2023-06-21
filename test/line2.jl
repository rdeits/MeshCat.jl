using Colors
using GeometryBasics
using MeshCat

vis = Visualizer()
open(vis)

θ = range(0, stop=2π, length=10)
setobject!(vis["Line2"], Line2())

points = [rand(3) for _ = 1:100]
pointcloud = PointCloud(points)

setobject!(vis, Object(pointcloud, material, "Line"))

material = LineMaterial(color=colorant"yellow", linewidth=8)
line = Line2(pointcloud)

setobject!(vis, line)

LineGeometry
