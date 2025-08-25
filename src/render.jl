struct DisplayedVisualizer
    core::CoreVisualizer
end


DisplayedVisualizer(vis::Visualizer) = DisplayedVisualizer(vis.core)

url(c::DisplayedVisualizer) = url(c.core)

"""
Render a MeshCat visualizer inline in Jupyter, Juno, or VSCode.

If this is the last command in a Jupyter notebook cell, then the
visualizer should show up automatically in the corresponding output
cell.

If this is run from the Juno console, then the visualizer should show
up in the Juno plot pane. Likewise if this is run from VSCode with
the julia-vscode extension, then the visualizer should show up in the
Julia Plots pane.
"""
render(vis::Visualizer) = render(vis.core)
render(core::CoreVisualizer) = DisplayedVisualizer(core)

@deprecate IJuliaCell(v::Visualizer) render(v)

function Base.show(io::IO,
        ::Union{MIME"text/html", MIME"juliavscode/html"},
        frame::DisplayedVisualizer)
    wait_for_server(frame.core)
    print(io, """
    <div style="height: 500px; width: 100%; overflow-x: auto; overflow-y: hidden; resize: both">
    <iframe src="$(url(frame))" style="width: 100%; height: 100%; border: none"></iframe>
    </div>
""")
end

function Base.show(io::IO,
        ::MIME"application/prs.juno.plotpane+html",
        d::DisplayedVisualizer)
    wait_for_server(d.core)
    print(io, """
    <div style="height: 100%; width: 100%; overflow-x: auto; overflow-y: hidden; resize: both">
    <iframe src="$(url(d.core))" style="width: 100%; height: 100%; border: none"></iframe>
    </div>
    """)
end

function _create_command(data::Vector{UInt8})
    return """
fetch("data:application/octet-binary;base64,$(base64encode(data))")
    .then(res => res.arrayBuffer())
    .then(buffer => viewer.handle_command_bytearray(new Uint8Array(buffer)));
    """
end

"""
Extract a single HTML document containing the entire MeshCat scene,
including all geometries, properties, and animations, as well as all
required javascript assets. The resulting HTML document should render
correctly after you've exited Julia, and even if you have no internet
access.
"""
static_html(vis::Visualizer) = static_html(vis.core)

function static_html(core::CoreVisualizer)
    viewer_commands = String[]

    foreach(core.tree) do node
        if node.object !== nothing
            push!(viewer_commands, _create_command(node.object));
        end
        if node.transform !== nothing
            push!(viewer_commands, _create_command(node.transform));
        end
        for data in values(node.properties)
            push!(viewer_commands, _create_command(data));
        end
        if node.animation !== nothing
            push!(viewer_commands, _create_command(node.animation))
        end
    end

    return """
        <!DOCTYPE html>
        <html>
            <head> <meta charset=utf-8> <title>MeshCat</title> </head>
            <body>
                <div id="meshcat-pane">
                </div>
                <script>
                    $(MAIN_JS_STRING)
                </script>
                <script>
                    var viewer = new MeshCat.Viewer(document.getElementById("meshcat-pane"));
                    $(join(viewer_commands, '\n'))
                </script>
                 <style>
                    body {margin: 0; }
                    #meshcat-pane {
                        width: 100vw;
                        height: 100vh;
                        overflow: hidden;
                    }
                </style>
                <script id="embedded-json"></script>
            </body>
        </html>
    """
end

struct StaticVisualizer
    core::CoreVisualizer
end

"""
Render a static version of the visualizer, suitable for embedding
and offline use. The embedded visualizer includes all geometries,
properties, and animations which have been added to the scene, baked
into a single HTML document. This document also includes the full
compressed MeshCat javascript source files, so it should render
properly even after you've exited Julia and even if you have no
internet access.

To get access to the raw static HTML representation, see `static_html`
"""
render_static(vis::Visualizer, args...; kw...) = render_static(vis.core)

render_static(core::CoreVisualizer) = StaticVisualizer(core)


_srcdoc_escape(x) = replace(replace(x, '&' => "&amp;"), '\"' => "&quot;")

function static_iframe_wrapper(html)
    id = uuid1()
    return """
        <div style="height: 500px; width: 100%; overflow-x: auto; overflow-y: hidden; resize: both">
        <iframe id="$id"
         style="width: 100%; height: 100%; border: none"
         srcdoc="$(_srcdoc_escape(html))">
        </iframe>
        </div>
    """
end

function Base.show(io::IO,
        ::Union{MIME"text/html", MIME"juliavscode/html"},
        static_vis::StaticVisualizer)
    print(io, static_iframe_wrapper(static_html(static_vis.core)))
end

