local skynet = require "skynet"
require "skynet.manager"
local utils = require "utils"

local CMD = {}
local minDist = 3
local pos = {}
local dir = utils.getInitDir()
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
		local nextDir
		if math.abs(pos.x-target.x) > math.abs(pos.y-target.y) then
			nextDir = utils.encodeDir(moveDir(pos.x, target.x), 0)
		else
			nextDir = utils.encodeDir(0, moveDir(pos.y, target.y))
		end
		skynet.call("scene", "lua", "move", "wolf", nextDir)
		dir = nextDir
	end
end

function CMD.react(attr)
	target.dist = nil
	for k, v in pairs(attr.updates) do
		if v.id ~= "wolf" then
			local d = dist(attr.x, attr.y, v.x, v.y)
			if d <= minDist then
				if target.dist == nil or d < target.dist then
					target.x = v.x
					target.y = v.y
					target.dist = d
				end
			end
		end
	end
	pos.x =attr.x
	pos.y = attr.y
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