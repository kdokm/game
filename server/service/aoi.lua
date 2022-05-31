local skynet = require "skynet"
require "skynet.manager"

local CMD = {}
observer = {}
observant = {}

local function inRange(x1, y1, x2, y2)
	local d = x1 - x2
	if d > 2 or d < -2 then
		return false
	end
	d = y1 - y2
	if d > 2 or d < -2 then
		return false
	end
	return true
end

function CMD.update(id, x, y, hp)
	local r = {}
	observer[id] = r
	observant[id] = r
	for k, v in pairs(observer) do
		table.insert(v, { id=id, x=x, y=y, hp=hp })
	end
	for k, v in pairs(observant) do
		table.insert(v, { id=id, x=x, y=y, hp=hp })
	end
end

function CMD.quit(id)
	observer[id] = nil
	observant[id] = nil
	for k, v in pairs(observer) do
		--todo
	end
	for k, v in pairs(observant) do
		--todo
	end
end

function CMD.get(id)
	return observer[id]
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
	skynet.register "aoi"
end)