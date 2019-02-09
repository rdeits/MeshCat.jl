
"""
    open(vis::Visualizer; host::IPAddr = ip"127.0.0.1", start_browser = true,
                          default_port = 8700, max_retries = 500)

Start a server for the visualizer so that it can be accessed from a browser
using the given host URL. This method will try to search for an open port,
starting at `default_port` and then trying `max_retries` additional port
numbers. If `start_browser` is true, then a new browser window will be opened.

    open(vis::Visualizer, port::Integer; host::IPAddr = ip"127.0.0.1", start_browser = true)

Start a server for the visualizer so that it can be accessed from a browser
using the given host URL and port. If `start_browser` is true, then a new
browser window will be opened.

"""
Base.open(vis::Visualizer, args...; kw...) = open(vis.core, args...; kw...)

function Base.open(core::CoreVisualizer, port::Integer;
                   host::IPAddr = ip"127.0.0.1", start_browser = true)
    @async WebIO.webio_serve(Mux.page("/", req -> core.scope), host, port)
    url = "http://$host:$port"
    @info("Serving MeshCat visualizer at $url")
    start_browser && open_url(url)
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

function Base.open(core::CoreVisualizer;
                   host::IPAddr=ip"127.0.0.1", default_port=8700, max_retries=500, kw...)
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
        return open(core, port; host=host, kw...)
    end
end
