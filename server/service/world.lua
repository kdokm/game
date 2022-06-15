local skynet = require "skynet"
require "skynet.manager"
local utils = require "utils"
local backend_utils = require "backend_utils"

local CMD = {}
local zones = {}
local amounts = {}

local function dispatch(id)
	local zone_id = nil
	local x, y
	local r = skynet.call("redis", "lua", "get", "P", id)
	if r == nil then
		for k, v in pairs(backend_utils.init_zones) do
			if zone_id == nil or amounts[v] < amounts[zone_id] then
				zone_id = v
			end
		end
		x, y = backend_utils.initPos(zone_id, "center")
	else
		x = tonumber(string.sub(r, 1, pos_digit))
                                y = tonumber(string.sub(r, pos_digit+1))
		zone_id = backend_utils.getZoneID(x, y)
	end
	return zone_id, x, y
end

function CMD.initPlayer(id, fd)
	local zone_id, x, y = dispatch(id)
	amounts[zone_id] = amounts[zone_id] + 1
	skynet.call(zones[zone_id], "lua", "initPlayer", id, fd, x, y)
	return zones[zone_id]
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
	skynet.register "world"
	for i = 0, backend_utils.num_zones_x * backend_utils.num_zones_y - 1 do
		zones[i] = skynet.newservice("zone")
		amounts[i] = 0
	end
	for k, v in pairs(zones) do
		skynet.call(v, "lua", "start", k, zones)
	end
end)