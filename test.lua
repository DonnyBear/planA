local skynet = require "skynet"

skynet.start(function()
	print("start main")
    skynet.uniqueservice("client")
	print("Main Server exit")
	skynet.exit()
end)