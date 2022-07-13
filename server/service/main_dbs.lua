local skynet = require "skynet"
local cluster = require "skynet.cluster"
local sprotoloader = require "sprotoloader"

local max_client = 64

skynet.start(function()
	skynet.error("DB Server start")
	skynet.uniqueservice("protoloader")
	if not skynet.getenv "daemon" then
		local console = skynet.newservice("console")
	end
	skynet.newservice("debug_console",8004)
	skynet.newservice("mongo")
	cluster.open("db")
	skynet.exit()
end)
