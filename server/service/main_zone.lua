local skynet = require "skynet"
local cluster = require "skynet.cluster"
local sprotoloader = require "sprotoloader"
local utils = require "utils"

local max_client = 64

skynet.start(function()
	skynet.error("Zone Server start")
	skynet.uniqueservice("protoloader")
	if not skynet.getenv "daemon" then
		local console = skynet.newservice("console")
	end
	skynet.newservice("debug_console",8003)
	for i = 0, utils.num_zones_x * utils.num_zones_y - 1 do
		local zone = skynet.newservice("zone")
		skynet.call(zone, "lua", "start", i)
	end
	cluster.open("zone")
	skynet.exit()
end)
