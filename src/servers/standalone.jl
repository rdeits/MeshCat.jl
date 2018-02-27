using MeshCat: open_url
using MeshCat.ZMQServer: ZMQWebSocketBridge, web_url

function serve()
    zmq_url = nothing
    open_browser = false
    for arg in ARGS
        info("arg:", arg)
        m = match(r"^\-\-zmq\-url=(.*)$", arg)
        info(m)
        if m !== nothing
            zmq_url = strip(m[1])
        end
        m = match(r"^\-\-open$", arg)
        if m !== nothing
            open_browser = true
        end
    end
    bridge = ZMQWebSocketBridge(zmq_url)
    if open_browser
        open_url(web_url(bridge))
    end
    run(bridge)
end

serve()
