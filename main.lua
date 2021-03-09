local skynet = require "skynet"

skynet.start(function()
	print("start main")
    -- skynet.newservice("fight")
    -- skynet.newservice("test")
    -- skynet.newservice("login_start")
    local watchdog = skynet.newservice("watchdog")
	skynet.call(watchdog, "lua", "start", {
		port = 8888,
		maxclient = max_client,
		nodelay = true,
	})
	print("Watchdog listen on ", 8888)
	print("Main Server exit")
	skynet.exit()
end)