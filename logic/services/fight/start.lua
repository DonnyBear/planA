local skynet = require "skynet"
require "skynet.manager"
local HANDLE = LoadModule("HANDLE", "./logic/services/fight/handle.lua")

skynet.start(function()
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(srv_iml[command])
		f(...)
	end)
	skynet.register(".fight")
end)

