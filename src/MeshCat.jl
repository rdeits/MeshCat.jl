__precompile__()

module MeshCat

import Base: delete!

export Visualizer,
	   IJuliaCell,
	   setobject!,
	   settransform!,
	   delete!,
	   url


include("servers.jl")
include("ijulia.jl")
include("geometry.jl")
include("objects.jl")
include("commands.jl")
include("lowering.jl")
include("msgpack.jl")
include("visualizer.jl")

end
