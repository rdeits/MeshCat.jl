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
