"""
Low-level type which manages the actual meshcat server. See [`Visualizer`](@ref)
for the public-facing interface.
"""
struct CoreVisualizer
    tree::SceneNode
    connections::Set{Any}
    host::IPAddr
    port::Int

    function CoreVisualizer(host::IPAddr = ip"127.0.0.1", default_port=8700)
        connections = Set([])
        tree = SceneNode()
        port = find_open_port(host, default_port, 500)
        core = new(tree, connections, host, port)
        start_server(core)
        return core
    end
end

function find_open_port(host, default_port, max_retries)
    for port in default_port:(default_port + max_retries)
        server = try
            listen(host, port)
        catch e
            if e isa Base.IOError
                continue
            end
        end
        close(server)
        # It is *possible* that a race condition could occur here, in which
        # some other process grabs the given port in between the close() above
        # and the open() below. But it's unlikely and would not be terribly
        # damaging (the user would just have to call open() again).
        return port
    end
end

function start_server(core::CoreVisualizer)
    asset_files = Set(["index.html", "main.min.js", "main.js"])

    function read_asset(file)
        if file in asset_files
            return open(s -> read(s, String), joinpath(VIEWER_ROOT, file))
        else
            return "Not found"
        end
    end
    default = "index.html"
    Mux.@app h = (
        Mux.defaults,
        Mux.page("/index.html", req -> read_asset("index.html")),
        Mux.page("/main.js", req -> read_asset("main.js")),
        Mux.page("/main.min.js", req -> read_asset("main.min.js")),
        Mux.page("/", req -> read_asset(default)),
        Mux.notfound());
    Mux.@app w = (
        Mux.wdefaults,
        Mux.route("/", req -> add_connection!(core, req)),
        Mux.wclose,
        Mux.notfound());
    @async begin
        # Suppress noisy unhelpful log messages from HTTP.jl, e.g.
        # https://github.com/JuliaWeb/HTTP.jl/issues/392
        Logging.with_logger(Logging.NullLogger()) do
            WebSockets.serve(
            WebSockets.ServerWS(
                Mux.http_handler(h),
                Mux.ws_handler(w),
            ), core.host, core.port);
        end
    end
    @info "MeshCat server started. You can open the visualizer by visiting the following URL in your browser:\n$(url(core))"
end

function url(core::CoreVisualizer)
    "http://$(core.host):$(core.port[])"
end

function add_connection!(core::CoreVisualizer, req)
    connection = req[:socket]
    push!(core.connections, connection)
    send_scene(core, connection)
    wait()
end

function update_tree!(core::CoreVisualizer, cmd::SetObject, data)
    core.tree[cmd.path].object = data
end

function update_tree!(core::CoreVisualizer, cmd::SetTransform, data)
    core.tree[cmd.path].transform = data
end

function update_tree!(core::CoreVisualizer, cmd::SetProperty, data)
    core.tree[cmd.path].properties[cmd.property] = data
end

function update_tree!(core::CoreVisualizer, cmd::Delete, data)
    if length(cmd.path) == 0
        core.tree = SceneNode()
    else
        delete!(core.tree, cmd.path)
    end
end

function update_tree!(core::CoreVisualizer, cmd::SetAnimation, data)
    core.tree.animation = data
end

function update_tree!(core::CoreVisualizer, cmd::TakeScreenshot, data)
    core.tree.animation = data
end

function send_scene(core::CoreVisualizer, connection)
    foreach(core.tree) do node
        if node.object !== nothing
            WebSockets.writeguarded(connection, node.object)
        end
        if node.transform !== nothing
            WebSockets.writeguarded(connection, node.transform)
        end
        for data in values(node.properties)
            WebSockets.writeguarded(connection, data)
        end
        if node.animation !== nothing
            WebSockets.writeguarded(connection, node.animation)
        end
    end
end

function Base.write(core::CoreVisualizer, data)
    for connection in core.connections
        if isopen(connection)
            WebSockets.writeguarded(connection, data)
        else
            delete!(core.connections, connection)
        end
    end
end

function send(core::CoreVisualizer, cmd::AbstractCommand)
    data = pack(lower(cmd))
    update_tree!(core, cmd, data)
    write(core, data)

    nothing
end

function Base.wait(core::CoreVisualizer)
    while isempty(core.connections)
        sleep(0.5)
    end
end

"""
    vis = Visualizer()

Construct a new MeshCat visualizer instance.

Useful methods:

    vis[:group1] # get a new visualizer representing a sub-tree of the scene
    setobject!(vis, geometry) # set the object shown by this visualizer's sub-tree of the scene
    settransform!(vis, tform) # set the transformation of this visualizer's sub-tree of the scene
    setvisible!(vis, false) # hide this part of the scene
"""
struct Visualizer <: AbstractVisualizer
    core::CoreVisualizer
    path::Path
end

Visualizer() = Visualizer(CoreVisualizer(), ["meshcat"])

"""
$(TYPEDSIGNATURES)

Wait until at least one browser has connected to the
visualizer's server. This is useful in scripts to delay
execution until the browser window has opened.
"""
Base.wait(v::Visualizer) = wait(v.core)

# IJuliaCell(vis::Visualizer; kw...) = iframe(vis.core; kw...)

Base.show(io::IO, v::Visualizer) = print(io, "MeshCat Visualizer with path $(v.path) at $(url(v.core))")

"""
Set the object at this visualizer's path. This replaces whatever
geometry was presently at that path.

$(TYPEDSIGNATURES)

To draw multiple geometries, place them at different paths by using the slicing notation:

    setobject!(vis[:group1][:box1], geometry1)
    setobject!(vis[:group1][:box2], geometry2)
"""
function setobject!(vis::Visualizer, obj::AbstractObject)
    send(vis.core, SetObject(obj, vis.path))
    vis
end

"""
Set the transform of this visualizer's path. This can be done before or after
adding an object at that path.

$(TYPEDSIGNATURES)

The overall transform of an object is the composition of the transforms of all
of its parents, so setting the transform of `vis[:group1]` affects the poses of
the objects at `vis[:group1][:box1]` and `vis[:group1][:box2]`.
"""
function settransform!(vis::Visualizer, tform::Transformation)
    send(vis.core, SetTransform(tform, vis.path))
    vis
end

"""
Delete the geometry at this visualizer's path and all of its descendants.

$(TYPEDSIGNATURES)
"""
function delete!(vis::Visualizer)
    send(vis.core, Delete(vis.path))
    vis
end

"""
Set a single property for the object at the given path.

$(TYPEDSIGNATURES)

(this is named setprop! instead of setproperty! to avoid confusion
with the Base.setproperty! function introduced in Julia v0.7)
"""
function setprop!(vis::Visualizer, property::AbstractString, value)
    send(vis.core, SetProperty(vis.path, property, value))
    vis
end

"""
Set the currently playing animation in the visualizer.

$(TYPEDSIGNATURES)

"""
function setanimation!(vis::Visualizer, anim::Animation; play::Bool=true, repetitions::Integer=1)
    cmd = SetAnimation(anim, play, repetitions)
    send(vis.core, cmd)
end

"""
Take a screenshot of the current visualizer.

$(TYPEDSIGNATURES)
"""
function takescreenshot!(vis::Visualizer)
    send(vis.core, TakeScreenshot())
    vis
end

"""
Get a new `Visualizer` representing a sub-tree of the same scene.

$(TYPEDSIGNATURES)

For example, if you have `vis::Visualizer` with path `/meshcat/foo`, you can do
`vis[:bar]` to get a new `Visualizer` with path `/meshcat/foo/bar`.
"""
Base.getindex(vis::Visualizer, path...) =
    Visualizer(vis.core, joinpath(vis.path, path...))
