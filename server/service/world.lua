local skynet = require "skynet"
require "skynet.manager"
local utils = require "utils"

local CMD = {}
local zones = {}
local amounts = {}

local function dispatch(id)
	local zone_id = nil
	local r = skynet.call("mongo", "lua", "getall", "S", id)
	if r == nil then
		for k, v in pairs(utils.init_zones) do
			if zone_id == nil or amounts[v] < amounts[zone_id] then
				zone_id = v
			end
		end
		r = {}
		r.x, r.y = utils.init_pos(zone_id, "center")
	else
		for k, v in pairs(r) do
			skynet.error(k, v)
		end
		zone_id = utils.get_zone_id(r.x, r.y)
	end
	return zone_id, r
end

function CMD.init_player(id, fd, agent)
	local zone_id, r = dispatch(id)
	r.fd = fd
	r.agent = agent
	amounts[zone_id] = amounts[zone_id] + 1
	skynet.call(zones[zone_id], "lua", "init_player", id, r)
	return zones[zone_id]
end

function CMD.update_zone(id, info, detail_attr, old, new)
	amounts[old] = amounts[old] - 1
	if new ~= nil then
		amounts[new] = amounts[new] + 1
		skynet.call(zones[new], "lua", "init_player", id, info, detail_attr)
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