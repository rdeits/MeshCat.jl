#!/usr/bin/env python

import sys
import asyncio

import websockets

async def listen(uri):
    async with websockets.connect(uri) as websocket:
        while True:
            msg = await websocket.recv()
            print("got message")

asyncio.get_event_loop().run_until_complete(
    listen(sys.argv[1]))