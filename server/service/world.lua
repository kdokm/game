local skynet = require "skynet"
require "skynet.manager"
local utils = require "utils"

local CMD = {}
local zones = {}
local amounts = {}

local function dispatch(id)
	local zone_id = nil
	local x, y
	local r = skynet.call("redis", "lua", "get", "P", id)
	if r == nil then
		for k, v in pairs(utils.init_zones) do
			if zone_id == nil or amounts[v] < amounts[zone_id] then
				zone_id = v
			end
		end
		x, y = utils.initPos(zone_id, "center")
	else
		x = tonumber(string.sub(r, 1, utils.pos_digit))
                                y = tonumber(string.sub(r, utils.pos_digit+1))
		zone_id = utils.getZoneID(x, y)
	end
	return zone_id, x, y
end

function CMD.initPlayer(id, fd)
	local zone_id, x, y = dispatch(id)
	amounts[zone_id] = amounts[zone_id] + 1
	skynet.call(zones[zone_id], "lua", "initPlayer", id, fd, {x=x, y=y})
	return zones[zone_id]
end

function CMD.updateZone(id, fd, attr, old, new)
	amounts[old] = amounts[old] - 1
	if new ~= nil then
		amounts[new] = amounts[new] + 1
		skynet.call(zones[new], "lua", "initPlayer", id, fd, attr)
		return zones[new]
	end
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
	skynet.register "world"
	for i = 0, utils.num_zones_x * utils.num_zones_y - 1 do
		zones[i] = skynet.newservice("zone")
		amounts[i] = 0
		skynet.call(zones[i], "lua", "start", i)
	end
end)