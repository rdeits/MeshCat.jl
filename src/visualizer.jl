mutable struct CoreVisualizer
    scope::WebIO.Scope
    tree::SceneNode
    command_channel::Observable{Vector{UInt8}}
    request_channel::Observable{String}
    controls_channel::Observable{Vector{Any}}
    controls::Dict{String, Tuple{Observable, AbstractControl}}

    function CoreVisualizer()
        scope = WebIO.Scope(
            imports=[
                "/pkg/MeshCat/meshcat/dist/main.min.js"
            ]
        )
        command_channel = Observable(scope, "meshcat-command", UInt8[])
        request_channel = Observable(scope, "meshcat-request", "")
        controls_channel = Observable(scope, "meshcat-controls", [])
        viewer_name = "meshcat_viewer_$(scope.id)"
        div_id = "$viewer_name"

        onimport(scope, @js function(mc)
            @var element = this.dom.querySelector("#" + $div_id)
            window[$viewer_name] = @new mc.Viewer(element)
            $request_channel[] = String(Date.now())
        end)

        onjs(command_channel, @js function(val)
            console.log("handling command")

            window[$viewer_name].handle_command_message(Dict(:data => val))
        end)
        # scope = scope(dom"iframe"(
        #     id=div_id,
        #     width="600",
        #     height="400"
        # ))
        scope = scope(dom"div.meshcat-viewer"(
            id=div_id,
            style=Dict(
                :width => "100%",
                :height => "100%",
                :position => "absolute",
                :left => 0,
                :right => 0,
            )
        ))

        tree = SceneNode()
        controls = Dict{String, Observable}()
        vis = new(scope, tree, command_channel, request_channel, controls_channel, controls)
        on(request_channel) do x
            send_scene(vis)
        end

        on(controls_channel) do msg
            name::String, value = msg
            if haskey(vis.controls, name)
                @async vis.controls[name] = value
                # Base.invokelatest(setindex!, vis.controls[name], value)
            end
        end
        vis
    end
end

function Base.show(io::IO, M::MIME"text/html", core::CoreVisualizer)
    node = dom"div"(
        core.scope,
        style=Dict(Symbol("min-height") => "400px")
    )
    show(io, M, node)
end


function update_tree!(core::CoreVisualizer, cmd::SetObject, data)
    core.tree[cmd.path].object = data
end

function update_tree!(core::CoreVisualizer, cmd::SetTransform, data)
    core.tree[cmd.path].transform = data
end

function update_tree!(core::CoreVisualizer, cmd::Delete, data)
    if length(cmd.path) == 0
        core.tree = SceneNode()
    else
        delete!(core.tree, cmd.path)
    end
end

# using Requires

# @require Mux @eval(
#         MeshCat,
#         function serve(core::CoreVisualizer, port::Integer=8000)
#             div = dom"div"(
#                 core.scope,
#                 style=Dict(:width => "100vw", :height => "100vh")
#             )
#             Main.webio_serve(Mux.page(req -> div), port)
#         end
#     )

update_tree!(core::CoreVisualizer, cmd::SetControl, data) = nothing

function send_scene(core::CoreVisualizer)
    foreach(core.tree) do node
        if !isnull(node.object)
            core.command_channel[] = get(node.object)
        end
        if !isnull(node.transform)
            core.command_channel[] = get(node.transform)
        end
    end
    for (name, (obs, control)) in core.controls
        send(core, SetControl(control))
    end
end

function Base.send(c::CoreVisualizer, cmd::AbstractCommand)
    data = pack(lower(cmd))
    update_tree!(c, cmd, data)
    c.command_channel[] = data
    nothing
end

# mutable struct ViewerWindow
#     context::ZMQ.Context
#     socket::ZMQ.Socket
#     web_url::String
#     zmq_url::String
#     bridge::Union{ZMQWebSocketBridge, Void}

#     function ViewerWindow(bridge::ZMQWebSocketBridge)
#         context = ZMQ.Context()
#         socket = ZMQ.Socket(context, ZMQ.REQ)
#         ZMQ.connect(socket, zmq_url(bridge))
#         new(context, socket, web_url(bridge), zmq_url(bridge), bridge)
#     end

#     function ViewerWindow(zmq_url::AbstractString)
#         context = ZMQ.Context()
#         socket = ZMQ.Socket(context, ZMQ.REQ)
#         ZMQ.connect(socket, zmq_url)
#         web_url = request_zmq_url(socket)
#         # Connect again, to work around weird bug in the Python version of the
#         # server. See https://github.com/rdeits/meshcat-python/pull/2
#         socket = ZMQ.Socket(context, ZMQ.REQ)
#         ZMQ.connect(socket, zmq_url)
#         new(context, socket, web_url, zmq_url, nothing)
#     end

#     function ViewerWindow()
#         bridge = ZMQWebSocketBridge()
#         @async run(bridge)
#         ViewerWindow(bridge)
#     end
# end

# function request_zmq_url(socket::ZMQ.Socket)
#     ZMQ.send(socket, "url")
#     zmq_url = unsafe_string(ZMQ.recv(socket))
# end

# url(c::ViewerWindow) = c.web_url
# Base.open(c::ViewerWindow) = open_url(url(c))
# function Base.close(c::ViewerWindow)
#     close(c.socket)
#     close(c.context)
# end

# function Base.wait(c::ViewerWindow)
#     ZMQ.send(c.socket, "wait")
#     ZMQ.recv(c.socket)
#     nothing
# end

# function Base.send(c::ViewerWindow, cmd::AbstractCommand)
#     data = lower(cmd)
#     ZMQ.send(c.socket, data["type"], true)
#     ZMQ.send(c.socket, data["path"], true)
#     ZMQ.send(c.socket, pack(data), false)
#     ZMQ.recv(c.socket)
#     nothing
# end

function open_url(url)
    try
        @static if is_windows()
            run(`start $url`)
        elseif is_apple()
            run(`open $url`)
        elseif is_linux()
            run(`xdg-open $url`)
        end
    catch e
        println("Could not open browser automatically: $e")
        println("Please open the following URL in your browser:")
        println(url)
    end
end

# """
#     vis = Visualizer()

# Construct a new MeshCat visualizer instance. This also starts the MeshCat ZeroMQ
# and file servers, choosing an appropriate port automatically.

# Useful methods:

#     open(vis) # open the visualizer in your browser
#     vis[:group1] # get a new visualizer representing a sub-tree of the scene
#     setobject!(vis[:group1], geometry) # set the object shown by this sub-tree of the visualizer

#     vis = Visualizer(zmq_url::String)

# Connect to an existing MeshCat server at the given ZeroMQ URL.
# """
struct Visualizer
    core::CoreVisualizer
    path::Path
end

Visualizer() = Visualizer(CoreVisualizer(), ["meshcat"])
# Visualizer(zmq_url::AbstractString) = Visualizer(ViewerWindow(zmq_url), ["meshcat"])

# """
# $(SIGNATURES)

# Get the URL at which the MeshCat file server is running.
# Open this URL in your browser to see the 3D scene.
# """
# url(v::Visualizer) = url(v.window)

# """
# Open the visualizer's web URL in your default browser
# """
# Base.open(v::Visualizer) = (open(v.window); v)
# Base.close(v::Visualizer) = close(v.window)
# Base.show(io::IO, v::Visualizer) = print(io, "MeshCat Visualizer at $(url(v)) with path $(v.path)")

# """
# $(SIGNATURES)

# Wait until at least one browser has connected to the
# visualizer's server. This is useful in scripts to delay
# execution until the browser window has opened.
# """
# Base.wait(v::Visualizer) = wait(v.window)

Base.show(io::IO, M::MIME"text/html", vis::Visualizer) = show(io, M, vis.core)

"""
$(SIGNATURES)

Set the object at this visualizer's path. This replaces whatever
geometry was presently at that path. To draw multiple geometries,
place them at different paths by using the slicing notation:

    setobject!(vis[:group1][:box1], geometry1)
    setobject!(vis[:group1][:box2], geometry2)
"""
function setobject!(vis::Visualizer, obj::AbstractObject)
    send(vis.core, SetObject(obj, vis.path))
    vis
end

setobject!(vis::Visualizer, geom::GeometryLike) = setobject!(vis, Mesh(geom))
setobject!(vis::Visualizer, cloud::PointCloud) = setobject!(vis, Points(cloud))
setobject!(vis::Visualizer, geom::GeometryLike, material::AbstractMaterial) = setobject!(vis, Mesh(geom, material))

"""
$(SIGNATURES)

Set the transform of this visualizer's path. This can be done
before or after adding an object at that path. The overall transform
of an object is the composition of the transforms of all of its parents,
so setting the transform of `vis[:group1]` affects the poses of the objects
at `vis[:group1][:box1]` and `vis[:group1][:box2]`.
"""
function settransform!(vis::Visualizer, tform::Transformation)
    send(vis.core, SetTransform(tform, vis.path))
    vis
end

"""
$(SIGNATURES)

Delete the geometry at this visualizer's path and all of its descendants.
"""
function delete!(vis::Visualizer)
    send(vis.core, Delete(vis.path))
    vis
end

function setcontrol!(vis::Visualizer, name::AbstractString, obs::Observable)
    control = Button(vis.core.controls_channel, name)
    vis.core.controls[name] = (obs, control)
    send(vis.core, SetControl(control))
    vis
end

function setcontrol!(vis::Visualizer, name::AbstractString, obs::Observable, value, min=zero(value), max=one(value))
    control = NumericControl(vis.core.controls_channel, name, value, min, max)
    vis.core.controls[name] = (obs, control)
    send(vis.core, SetControl(control))
    vis
end

Base.getindex(vis::Visualizer, path::Union{Symbol, AbstractString}...) = Visualizer(vis.core, vcat(vis.path, path...))

