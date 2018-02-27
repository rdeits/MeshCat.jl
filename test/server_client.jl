@testset "server + client" begin
    script = joinpath(@__DIR__, "..", "src", "servers", "standalone.jl")
    cmd = `$(joinpath(JULIA_HOME, "julia")) -- $script --zmq-url="tcp://127.0.0.1:5568" --open`
    stream, proc = open(cmd)
    try
        line = readline(stream)
        @show line
        @test match(r"^Listening on 127.0.0.1\:[0-9]*", line) !== nothing
        line = readline(stream)
        @show line
        m = match(r"^zmq_url=(.*)$", line)
        @test m !== nothing
        zmq_url = m[1]
        @test zmq_url == "tcp://127.0.0.1:5568"
        line = readline(stream)
        m = match(r"^web_url=(.*)$", line)
        @show line
        @test m !== nothing
        web_url = m[1]

        vis = Visualizer(zmq_url)
        @test url(vis) == web_url

        println("waiting for vis")
        wait(vis)
        println("websocket connected")
        setobject!(vis, HyperSphere(Point(0., 0, 0), 0.5))
        settransform!(vis, Translation(0, 0, 1))
    finally
        kill(proc)
    end
end