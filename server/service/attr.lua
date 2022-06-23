local skynet = require "skynet"
local utils = require "utils"
local equation = require "equation"

local attr = {}

local function init_attr(id)
	local a = {}
	a.level = 1
	a.exp = 0
	skynet.call("redis", "lua", "hset", "A", id, "level", 1)
	for k, v in pairs(equation.attr) do
		a[v] = equation.get_init_attr_val()
		skynet.call("redis", "lua", "hset", "A", id, v, a[v])
	end
	return a
end

function attr.get_attr(id)
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

function attr.update_attr(id, a)
	local r = attr.get_attr(id)
	for k, v in pairs(a) do
		skynet.call("redis", "lua", "hset", "A", id, k, v)
	end
end

function attr.get_skill(id)
end

function attr.update_skill(id)
end

return attr