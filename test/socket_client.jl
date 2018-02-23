# Example of DandelionWebSocket.jl:
# Send some text and binary frames to ws://echo.websocket.org,
# which echoes them back.

using Requests: URI

using DandelionWebSockets

import DandelionWebSockets: on_text, on_binary,
                            state_connecting, state_open, state_closing, state_closed

mutable struct MockHandler <: WebSocketHandler
    client::WSClient
    stop_channel::Channel{Any}
end

# These are called when you get text/binary frames, respectively.
on_text(::MockHandler, s::String)  = println("Received text")
on_binary(::MockHandler, data::Vector{UInt8}) = println("Received data")

function state_closed(::MockHandler)
    println("State: CLOSED")

    # Signal the script that the connection is closed.
    put!(stop_chan, true)
end

stop_chan = Channel{Any}(1)

# Create a WSClient, which we can use to connect and send frames.
client = WSClient()
handler = MockHandler(client, stop_chan)

uri = URI("ws://localhost:$(ARGS[1])")
println("Connecting to $uri... ")

wsconnect(client, uri, handler)
println("Connected.")
# The second message on `stop_chan` indicates that the connection is closed, so we can exit.
take!(stop_chan)
