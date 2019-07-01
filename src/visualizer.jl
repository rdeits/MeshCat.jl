mutable struct CoreVisualizer
    scope::WebIO.Scope
    tree::SceneNode
    command_channel::Observable{Vector{UInt8}}
    request_channel::Observable{String}
    controls_channel::Observable{Vector{Any}}
    controls::Dict{String, Tuple{Observable, AbstractControl}}

    function CoreVisualizer()
        scope = WebIO.Scope(imports=ASSET_KEYS)
        command_channel = Observable(scope, "meshcat-command", UInt8[])
        request_channel = Observable(scope, "meshcat-request", "")
        controls_channel = Observable(scope, "meshcat-controls", [])
        viewer_name = "meshcat_viewer_$(scope.id)"

        onimport(scope, @js function(mc)
            @var element = this.dom.children[0]
            this.viewer = @new mc.Viewer(element)
            $request_channel[] = String(Date.now())
            window.document.body.style.margin = "0"
            window.meshcat_viewer = this.viewer
        end)

        onjs(command_channel, @js function(val)
            this.viewer.handle_command_message(Dict(:data => val))
        end)
        scope = scope(dom"div.meshcat-viewer"(
            style=Dict(
                :width => "100vw",
                :height => "100vh",
                :position => "absolute",
                :left => 0,
                :right => 0,
                :margin => 0,
            )
        ))
        scope.dom.props[:style][:overflow] = "hidden"

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

WebIO.render(core::CoreVisualizer) = core.scope

function WebIO.iframe(core::CoreVisualizer; height="100%", width="100%", minHeight="400px")
    ifr = WebIO.iframe(core.scope)
    onimport(ifr, @js function()
        this.dom.style.height = "100%"
        window.foo = this
        this.dom.children[0].children[0].style.flexGrow = "1"
    end)
    style = get!(Dict, ifr.dom.props, :style)
    style[:height] = height
    style[:minHeight] = minHeight
    style[:width] = width
    style[:display] = "flex"
    style[:flexDirection] = "column"
    ifr
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

update_tree!(core::CoreVisualizer, cmd::SetControl, data) = nothing
update_tree!(core::CoreVisualizer, cmd::SetAnimation, data) = nothing
update_tree!(core::CoreVisualizer, cmd::SetProperty, data) = nothing

function send_scene(core::CoreVisualizer)
    foreach(core.tree) do node
        if node.object !== nothing
            core.command_channel[] = node.object
        end
        if node.transform !== nothing
            core.command_channel[] = node.transform
        end
    end
    for (name, (obs, control)) in core.controls
        send(core, SetControl(control))
    end
end

function send(c::CoreVisualizer, cmd::AbstractCommand)
    data = pack(lower(cmd))
    update_tree!(c, cmd, data)
    c.command_channel[] = data
    nothing
end

Base.wait(c::CoreVisualizer) = WebIO.ensure_connection(c.scope.pool)

"""
    vis = Visualizer()

Construct a new MeshCat visualizer instance.

Useful methods:

    vis[:group1] # get a new visualizer representing a sub-tree of the scene
    setobject!(vis, geometry) # set the object shown by this visualizer's sub-tree of the scene
    settransform!(vis], tform) # set the transformation of this visualizer's sub-tree of the scene
"""
struct Visualizer <: AbstractVisualizer
    core::CoreVisualizer
    path::Path
end

Visualizer() = Visualizer(CoreVisualizer(), ["meshcat"])

"""
$(SIGNATURES)

Wait until at least one browser has connected to the
visualizer's server. This is useful in scripts to delay
execution until the browser window has opened.
"""
Base.wait(v::Visualizer) = wait(v.core)

IJuliaCell(vis::Visualizer; kw...) = iframe(vis.core; kw...)

Base.show(io::IO, v::Visualizer) = print(io, "MeshCat Visualizer with path $(v.path)")

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

"""
$(SIGNATURES)

Set a single property for the object at the given path.

(this is named setprop! instead of setproperty! to avoid confusion
with the Base.setproperty! function introduced in Julia v0.7)
"""
function setprop!(vis::Visualizer, property::AbstractString, value)
    send(vis.core, SetProperty(vis.path, property, value))
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

function setanimation!(vis::Visualizer, anim::Animation; play::Bool=true, repetitions::Integer=1)
    cmd = SetAnimation(anim, play, repetitions)
    send(vis.core, cmd)
end

Base.getindex(vis::Visualizer, path...) =
    Visualizer(vis.core, joinpath(vis.path, path...))
