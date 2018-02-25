module ZMQServer

using ..SceneTrees: SceneNode

using HttpServer
using WebSockets
using ZMQ

export ZMQWebSocketBridge, zmq_url, web_url

const VIEWER_ROOT = abspath(joinpath(@__DIR__, "..", "..", "viewer", "static"))
const VIEWER_HTML = "meshcat.html"
const DEFAULT_FILESERVER_PORT = 7000
const MAX_ATTEMPTS = 1000
const DEFAULT_ZMQ_METHOD = "tcp"
const DEFAULT_ZMQ_PORT = 6000

function handle_file_request(req, res)
    # This file handler is *extremely* simple, by design. I'm not currently
    # confident that I can write a secure file server that only serves files
    # inside the viewer root, so instead I am manually whitelisting the files
    # that might need to be served.
    if req.resource == "/static" || req.resource == "/static/" || req.resource == joinpath("/static", VIEWER_HTML)
        file = open(joinpath(VIEWER_ROOT, VIEWER_HTML))
    elseif req.resource in [
        "/static/js/LoaderSupport.js",
        "/static/js/OBJLoader.js",
        "/static/js/OBJLoader2.js",
        "/static/js/OrbitControls.js",
        "/static/js/dat.gui.js",
        "/static/js/meshcat.js",
        "/static/js/msgpack.min.js",
        "/static/js/split.min.js",
        "/static/js/three.js"
        ]
        file = open(joinpath(VIEWER_ROOT, "js", splitdir(req.resource)[2]))
    else
        return Response(404)
    end
    return Response(read(file))
end

function find_available_port(f::Function, default=8000, max_attempts=1000)
    for i in 1:max_attempts
        port = default + i - 1
        try
            return f(port), port
        catch e
            if e isa Base.UVError || e isa ZMQ.StateError
                println("Port $port in use, trying another")
            else
                rethrow(e)
            end
        end
    end
    error("Could not find an available port in the range [$default, $(default+max_attempts))")
end

mutable struct ZMQWebSocketBridge
    host::IPv4
    websockets::Set{WebSocket}
    tree::SceneNode
    web_port::Int
    web_server::Server
    zmq_context::ZMQ.Context
    zmq_socket::ZMQ.Socket
    zmq_url::String

    function ZMQWebSocketBridge(zmq_url=nothing, host::IPv4=IPv4(127,0,0,1), port=nothing)
        HttpServer.initcbs()
        bridge = new(host, Set{WebSocket}(), SceneNode())

        if port === nothing
            bridge.web_server, bridge.web_port = find_available_port(DEFAULT_FILESERVER_PORT, MAX_ATTEMPTS) do port
                start_server(bridge, port)
            end
        else
            bridge.web_port = port
            bridge.web_server = start_server(bridge, port)
        end
        yield()

        bridge.zmq_context = Context()

        if zmq_url === nothing
            (bridge.zmq_socket, bridge.zmq_url), _ = find_available_port(DEFAULT_ZMQ_PORT, MAX_ATTEMPTS) do port
                zmq_url = "$(DEFAULT_ZMQ_METHOD)://$(bridge.host):$port"
                start_zmq(bridge, zmq_url), zmq_url
            end
        else
            bridge.zmq_url = zmq_url
            bridge.zmq_socket = start_zmq(zmq_url)
        end
        println(zmq_url)
        println(web_url(bridge))
        bridge
    end
end

zmq_url(b::ZMQWebSocketBridge) = b.zmq_url
web_url(b::ZMQWebSocketBridge) = "http://$(b.host):$(b.web_port)/static/"

function WebSockets.WebSocketHandler(bridge::ZMQWebSocketBridge)
    WebSocketHandler() do req, client
        push!(bridge.websockets, client)
        send_scene(bridge, client)
        try
            while true
                read(client)
            end
        catch e
            if e isa WebSockets.WebSocketClosedError
                if client in bridge.websockets
                    delete!(bridge.websockets, client)
                end
            end
        end
    end
end


function start_server(bridge::ZMQWebSocketBridge, port)
    server = Server(HttpHandler(handle_file_request), WebSocketHandler(bridge))
    listen(server, bridge.host, port)
    @async HttpServer.handle_http_request(server)
    return server
end

function start_zmq(bridge::ZMQWebSocketBridge, url::String)
    socket = Socket(bridge.zmq_context, REP)
    ZMQ.bind(socket, url)
    socket
end

function wait_for_websockets(bridge::ZMQWebSocketBridge)
    while length(bridge.websockets) == 0
        sleep(0.1)
    end
end

function recv_multipart(sock::ZMQ.Socket)
    frames = [ZMQ.recv(sock)]
    while ZMQ.ismore(sock)
        push!(frames, ZMQ.recv(sock))
    end
    frames
end

function send_to_websockets(bridge::ZMQWebSocketBridge, msg)
    @sync begin
        for websocket in bridge.websockets
            @async begin
                if isopen(websocket)
                    write(websocket, msg)
                end
            end
        end
    end
end

function update_tree!(bridge::ZMQWebSocketBridge, command::String, path::AbstractVector, data)
    if command == "set_object"
        bridge.tree[path].object = data
    elseif command == "set_transform"
        bridge.tree[path].transform = data
    else
        @assert command == "delete"
        delete!(bridge.tree, path)
    end
end

function send_scene(bridge::ZMQWebSocketBridge, websocket::WebSocket)
    @sync begin
        foreach(bridge.tree) do node
            if !isnull(node.object)
                @async write(websocket, get(node.object))
            end
            if !isnull(node.transform)
                @async write(websocket, get(node.transform))
            end
        end
    end
end

function Base.run(bridge::ZMQWebSocketBridge)
    while true
        frames = recv_multipart(bridge.zmq_socket)
        command = unsafe_string(frames[1])
        if command == "url"
            ZMQ.send(bridge.zmq_socket, web_url(bridge))
        elseif command == "wait"
            wait_for_websockets(bridge)
            ZMQ.send(bridge.zmq_socket, "ok")
        elseif command in ["set_object", "set_transform", "delete"]
            path = split(unsafe_string(frames[2]), '/')
            data = take!(convert(IOStream, frames[3]))
            send_to_websockets(bridge, data)
            update_tree!(bridge, command, path, data)
            ZMQ.send(bridge.zmq_socket, "ok")
        else
            ZMQ.send(bridge.zmq_socket, "error: unrecognized command")
        end
    end
end

end