
struct IJuliaCell

	window::ViewerWindow
    embed::Bool

    IJuliaCell(window, embed=false) = new(window, embed)
end

IJuliaCell(v::Visualizer) = IJuliaCell(v.window)

url(c::IJuliaCell) = url(c.window)

function Base.show(io::IO, ::MIME"text/html", frame::IJuliaCell)
    if frame.embed
        show_embed(io, frame)
    else
        show_inline(io, frame)
    end
end

const iframe_attrs = "height=\"100%\" width=\"100%\" style=\"min-height: 500px;\""

function show_inline(io::IO, frame::IJuliaCell)
    print(io, """
    <div style="height: 500px; width: 500px; overflow-x: auto; overflow-y: hidden; resize: both">
    <iframe src="$(url(frame))" style="width: 100%; height: 100%; border: none"></iframe>
    </div>
""")
end

srcdoc_escape(x) = replace(replace(x, "&", "&amp;"), "\"", "&quot;")

function show_embed(io::IO, frame::IJuliaCell)
    id = Base.Random.uuid1()
    print(io, """
    <div style="height: 500px; width: 500px; overflow-x: auto; overflow-y: auto; resize: both">
    <iframe id="$id" srcdoc="$(srcdoc_escape(readstring(open(joinpath(@__DIR__, "..", "..", "viewer", "build", "inline.html")))))" style="width: 100%; height: 100%; border: none">
    </iframe>
    </div>
    <script>
    function try_to_connect() {
        console.log("trying");
        let frame = document.getElementById("$id");
        if (frame && frame.contentWindow !== undefined && frame.contentWindow.connect !== undefined) {
            frame.contentWindow.connect("$(url(frame))");
        } else {
            console.log("could not connect");
          setTimeout(try_to_connect, 100);
        }
    }
    setTimeout(try_to_connect, 1);
    </script>
    """)
end

# struct Snapshot
# 	json::String

#     Snapshot(fname::AbstractString) = new(open(readstring, fname))
#     Snapshot(io::IO) = new(readstring(io))
# end

# function Base.show(io::IO, ::MIME"text/html", snap::Snapshot)
# 	content = readstring(open(joinpath(viewer_root, "build", "inline.html")))
# 	# TODO: there has to be a better way than doing a replace() on the html.
# 	script = """
# 	<script>
# 	scene = new THREE.ObjectLoader().parse(JSON.parse(`$(snap.json)`));
# 	update_gui();
# 	</script>
# 	</body>
# 	"""
# 	html = replace(content, "</body>", script)
# 	print(io, """
# 	<iframe srcdoc="$(srcdoc_escape(html))" $iframe_attrs>
# 	</iframe>
# 	""")
# end

# function save(fname::String, snap::Snapshot)
#     content = readstring(open(joinpath(viewer_root, "build", "inline.html")))
#     # TODO: there has to be a better way than doing a replace() on the html.
#     script = """
#     <script>
#     scene = new THREE.ObjectLoader().parse(JSON.parse(`$(snap.json)`));
#     update_gui();
#     </script>
#     </body>
#     """
#     html = replace(content, "</body>", script)
#     open(fname, "w") do file
#         write(file, html)
#     end
# end
