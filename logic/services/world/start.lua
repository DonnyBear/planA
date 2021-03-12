local skynet = require "skynet"
require "skynet.manager"

skynet.start(function()
	skynet.send(".fight", "lua", "srv_test", 19)
	skynet.register(".world")
end)

