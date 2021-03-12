local skynet = require "skynet"
local socket = require "skynet.socket"
local service = require "skynet.service"
local websocket = require "http.websocket"
local protobuf = require "protobuf"

local handle = {}
local watchdog
local gate
local client
local MODE = ...

protobuf.register_file "./logic/proto/cs.pb"

function handle.connect(id)
    print("ws connect from: " .. tostring(id))
end

function handle.handshake(id, header, url)
    local addr = websocket.addrinfo(id)
    print("ws handshake from: " .. tostring(id), "url", url, "addr:", addr)
    print("----header-----")
    for k,v in pairs(header) do
        print(k,v)
    end
    print("--------------")
end

function handle.message(id, msg, msg_type)
    assert(msg_type == "binary" or msg_type == "text")
    print("agent handle message")
    local data = protobuf.decode("cs.Person", msg)
    for k, v in pairs(data) do
        print(k, v)
    end
    websocket.write(id, msg)
end

function handle.ping(id)
    print("ws ping from: " .. tostring(id) .. "\n")
end

function handle.pong(id)
    print("ws pong from: " .. tostring(id))
end

function handle.close(id, code, reason)
    print("ws close from: " .. tostring(id), code, reason)
end

function handle.error(id)
    print("ws error from: " .. tostring(id))
end

skynet.start(function ()
    print("new agent start")
    skynet.dispatch("lua", function (_,_, param)
        client = param.client
        watchdog = param.watchdog
        gate = param.gate
        local protocol = param.protocol
        print("agent dispatch", client, handle, protocol, addr)
        local ok, err = websocket.accept(client, handle, protocol, addr)
        if not ok then
            print(err)
        end
    end)
end)