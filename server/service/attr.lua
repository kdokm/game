local skynet = require "skynet"
local utils = require "utils"
local equation = require "equation"

local attr = {}

function attr.update_attr(id, a)
	for k, v in pairs(a) do
		skynet.call("redis", "lua", "hset", "A", id, k, v)
	end
end

function attr.get_attr(id)
	skynet.error("get attr info")
	local r = skynet.call("redis", "lua", "hgetall", "A", id)
	local a = {}
	if next(r) == nil then
		a.level = 1
		for i = 1, #equation.attr do
			a[equation.attr[i]] = equation.get_init_attr_val()
		end
		attr.update_attr(id, a)
	else
		for i = 1, #r, 2 do
			a[r[i]] = r[i+1]
		end
	end
	return a
end

function attr.get_skill(id)
end

function attr.update_skill(id)
end

return attr