local skynet = require "skynet"
require "skynet.manager"
local utils = require "utils"

local CMD = {}
local minDist = 3
local pos = {}
local dir = utils.getInitDir()
local entities = {}
local target = {}

local function dist(x1, y1, x2, y2)
	return math.abs(x1-x2) + math.abs(y1-y2)
end

local function moveDir(current, target)
	if current > target then
		return -1
	else
		return 1
	end
end

local function action()
	local x, y = utils.decodeDir(dir)
	if utils.inRangeSquare(pos.x+x, pos.y+y, target.x, target.y, 1) then
		skynet.call("scene", "lua", "attack", "wolf")
	else
		if math.abs(pos.x-target.x) > math.abs(pos.y-target.y) then
			dir = utils.encodeDir(moveDir(pos.x, target.x), 0)
		else
			dir = utils.encodeDir(0, moveDir(pos.y, target.y))
		end
		skynet.call("scene", "lua", "move", "wolf", dir)
	end
end

function CMD.react(attr)
	local flag = true
	for k, v in pairs(attr.updates) do
		if v.id ~= "wolf" then
			entities[v.id] = v
		end
		if v.id == target.id then
			flag = false
		end
	end

	local set
	if pos.x == attr.x and pos.y == attr.y and flag then
		set = attr.updates
	else
		set = entities
		target.dist = nil
		pos.x = attr.x
		pos.y = attr.y
	end

	for k, v in pairs(set) do
		local d = dist(attr.x, attr.y, v.x, v.y)
		if d <= minDist then
			if target.dist == nil or d < target.dist then
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
	skynet.register "monster"
	skynet.call("scene", "lua", "initMonster", "wolf", {})
	skynet.fork(function()
		while true do
			if target.dist ~= nil then
				action()
			end
			skynet.sleep(100)
		end
	end)
end)