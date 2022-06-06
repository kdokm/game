local skynet = require "skynet"
require "skynet.manager"

local CMD = {}
local minDist = 3
local target = {}

local function dist(x1, y1, x2, y2)
	return math.abs(x1-x2) + math.abs(y1-y2)
end

local function inRange(x1, y1, x2, y2, r)
	local d = x1 - x2
	if d > r or d < -r then
		return false
	end
	d = y1 - y2
	if d > r or d < -r then
		return false
	end
	return true
end

local function action()

end

function CMD.react(attr)
	target.dist == nil
	for k, v in pairs(attr.updates) do
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
			skynet.sleep(50)
		end
	end)
end)