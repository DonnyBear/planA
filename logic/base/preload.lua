-- This file will execute before every lua service start
-- See config

print("PRELOAD", ...)

dofile("./logic/base/import.lua")
dofile("./logic/base/msg_server.lua")