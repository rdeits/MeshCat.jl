module Servers
    module MuxProvider
        using Compat
        using Mux
        using WebIO
        using JSON

        # This module was copied over from
        # https://github.com/JuliaGizmos/WebIO.jl/blob/8e25ed2f9cf3158652907735bd44420205a105d9/src/providers/mux.jl
        # to attempt to avoid inference issues described in:
        # https://github.com/JuliaLang/julia/issues/21653
        function webio_serve(app, port=8000)
            http = Mux.App(Mux.mux(
                Mux.defaults,
                app,
                Mux.notfound()
            ))

            websock = Mux.App(Mux.mux(
                Mux.wdefaults,
                route("/webio-socket", create_socket),
                Mux.wclose,
                Mux.notfound(),
            ))

            serve(http, websock, port)
        end

        struct WebSockConnection <: AbstractConnection
            sock
        end

        function create_socket(req)
            sock = req[:socket]
            conn = WebSockConnection(sock)

            t = @async while isopen(sock)
                data = read(sock)

                msg = JSON.parse(String(data))
                WebIO.dispatch(conn, msg)
            end

            wait(t)
        end

        function Base.send(p::WebSockConnection, data)
            write(p.sock, sprint(io->JSON.print(io,data)))
        end

        Base.isopen(p::WebSockConnection) = isopen(p.sock)
    end

    using .MuxProvider: webio_serve
    using MeshCat: CoreVisualizer, Visualizer
    using Mux: page
    using Compat

    Base.open(vis::Visualizer, args...; kw...) = open(vis.core, args...; kw...)

    function Base.open(core::CoreVisualizer, port::Integer)
        webio_serve(page("/", req -> core.scope), port)
        url = "http://127.0.0.1:$port"
        Compat.@info("Serving MeshCat visualizer at $url")
        open_url(url)
    end

    function open_url(url)
        try
            if is_windows()
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

    function Base.open(core::CoreVisualizer; default_port=8700, max_retries=500)
        for port in default_port + (0:max_retries)
            server = try
                listen(port)
            catch e
                if e isa Base.UVError
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
end

module BlinkInterface
    using Requires
    using MeshCat: CoreVisualizer

    @require Blink begin
        function Base.open(core::CoreVisualizer, w::Blink.AtomShell.Window)
            # Ensure the window is ready
            Blink.js(w, "ok")
            # Set its contents
            Blink.body!(w, core.scope)
            w
        end
    end
end
