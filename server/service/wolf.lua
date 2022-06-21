local skynet = require "skynet"
require "skynet.manager"
local utils = require "utils"

local CMD = {}
local min_dist = 3
local pos = {}
local dir = utils.get_init_dir()
local entities = {}
local target = {}
local zone
local monster_id

local function move_dir(current, target)
	if current > target then
		return -1
	else
		return 1
	end
end

local function action()
	if target.id ~= nil then
		skynet.error(target.id)
		local x, y = utils.decode_dir(dir)
		if utils.in_range_square(pos.x+x, pos.y+y, target.x, target.y, 1) then
			skynet.call(zone, "lua", "attack", monster_id)
		else
			if math.abs(pos.x-target.x) > math.abs(pos.y-target.y) then
				dir = utils.encodeDir(move_dir(pos.x, target.x), 0)
			else
				dir = utils.encodeDir(0, move_dir(pos.y, target.y))
			end
			skynet.call(zone, "lua", "move", monster_id, dir)
		end
	end
end

function CMD.start(z, id)
	zone = z
	monster_id = id
	skynet.call(zone, "lua", "init_monster", monster_id, {})
	skynet.fork(function()
		while true do
			if target.dist ~= nil then
				action()
			end
			skynet.sleep(100)
		end
	end)
end

function CMD.react(attr)
	local flag = true
	for k, v in pairs(attr.updates) do
		entities[v.id] = v
		if v.id == target.id then
			flag = false
		end
	end

	local set
	if pos.x == attr.x and pos.y == attr.y and flag then
		set = attr.updates
	else
		set = entities
		target.id = nil
		pos.x = attr.x
		pos.y = attr.y
	end

	for k, v in pairs(set) do
		local d = utils.dist(attr.x, attr.y, v.x, v.y)
		if v.type == "player" and v.hp ~= 0 and d <= min_dist then
			if target.id == nil or d < target.dist then
				target.x = v.x
				target.y = v.y
				target.dist = d
				target.id = v.id
			end
		end
	end
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)