local skynet = require "skynet"
local cluster = require "skynet.cluster"
local sprotoloader = require "sprotoloader"

local max_client = 64

skynet.start(function()
	skynet.error("Conn Server start")
	skynet.uniqueservice("protoloader")
	if not skynet.getenv "daemon" then
		local console = skynet.newservice("console")
	end
	skynet.newservice("debug_console",8001)
	local watchdog = skynet.newservice("watchdog")
	skynet.call(watchdog, "lua", "start", {
		port = 8888,
		maxclient = max_client,
		nodelay = true,
	})
	skynet.error("Watchdog listen on", 8888)
	cluster.open("conn")
	skynet.exit()
end)
