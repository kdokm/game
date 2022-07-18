local skynet = require "skynet"
require "skynet.manager"
local utils = require "utils"
local equation = require "equation"

local CMD = {}

local function init_attr(id)
	local a = {}
	a.level = 1
	for k, v in pairs(utils.attr) do
		a[v] = equation.get_init_attr_val()
	end
	skynet.call("redis", "lua", "hset", "A", id, a)
	return a
end

function CMD.get_attr(id)
	skynet.error("get attr info")
	local r = skynet.call("redis", "lua", "hgetall", "A", id)
	local a = {}
	if next(r) == nil then
		a = init_attr(id)
	else
		for i = 1, #r, 2 do
			a[r[i]] = r[i+1]
		end
	end
	return a
end

function CMD.update_attr(id, a)
	skynet.call("redis", "lua", "hset", "A", id, a)
	return CMD.get_attr(id)
end

function CMD.get_skill(id)
end

function CMD.update_skill(id)
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
	skynet.register ".attr"
end)