local skynet = require "skynet"
local cluster = require "skynet.cluster"
local sprotoloader = require "sprotoloader"

local max_client = 64

skynet.start(function()
	skynet.error("Global Server start")
	skynet.uniqueservice("protoloader")
	if not skynet.getenv "daemon" then
		local console = skynet.newservice("console")
	end
	skynet.newservice("debug_console",8000)
	skynet.newservice("login")
	skynet.newservice("friend")
	cluster.open("global")
	skynet.exit()
end)
