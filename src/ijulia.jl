struct IJuliaCell
    core::CoreVisualizer
end

"""
Render a MeshCat visualizer inline inside a Jupyter notebook cell.

The visualizer should show up automatically in your Jupyter cell output
as long as this command is the *last* command in the input cell.
"""
IJuliaCell(v::Visualizer) = IJuliaCell(v.core)

url(c::IJuliaCell) = url(c.core)

function Base.show(io::IO, ::MIME"text/html", frame::IJuliaCell)
    wait_for_server(frame.core)
    print(io, """
    <div style="height: 500px; width: 100%; overflow-x: auto; overflow-y: hidden; resize: both">
    <iframe src="$(url(frame))" style="width: 100%; height: 100%; border: none"></iframe>
    </div>
""")
end
