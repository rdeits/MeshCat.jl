
Base.open(vis::Visualizer, args...; kw...) = open(vis.core, args...; kw...)

function Base.open(core::CoreVisualizer, port::Integer)
    @async WebIO.webio_serve(Mux.page("/", req -> core.scope), port)
    url = "http://127.0.0.1:$port"
    @info("Serving MeshCat visualizer at $url")
    open_url(url)
end

function open_url(url)
    try
        if Sys.iswindows()
            run(`cmd.exe /C "start $url"`)
        elseif Sys.isapple()
            run(`open $url`)
        elseif Sys.islinux()
            run(`xdg-open $url`)
        end
    catch e
        println("Could not open browser automatically: $e")
        println("Please open the following URL in your browser:")
        println(url)
    end
end

function Base.open(core::CoreVisualizer; default_port=8700, max_retries=500)
    for port in default_port:(default_port + max_retries)
        server = try
            listen(port)
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
        return open(core, port)
    end
end
