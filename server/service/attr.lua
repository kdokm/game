local skynet = require "skynet"
local equation = require "equation"

local attr = {}
local client_id
local posDigit = 3

function attr.init(id)
	client_id = id
end

local function addDetail(attrs, equips)
	local detail = equation.calDetail(attrs, equips)
	for k, v in pairs(detail) do
		attrs[k] = v
	end
	return attrs
end

function attr.getAttr(equips)
	skynet.error("get attr info")
	local r = skynet.call("redis", "lua", "hgetall", "A", client_id)
	r["free"] = equation.calFreeAttrs(r)
	r = addDetail(r, equips)
	return r
end

function attr.updateAttr(attrs)
	for k, v in pairs(attrs) do
		skynet.call("redis", "lua", "hset", "A", client_id, k, v)
	end
end

function attr.getSkill()
end

function attr.updateSkill()
end

function attr.getPos()
	local r = skynet.call("redis", "lua", "get", "P", client_id)
	return r
end

function attr.move(x, y)
	local r = getPos()
	local newX = tonumber(string.sub(r, 1, posDigit)) + x
	local newY = tonumber(string.sub(r, posDigit+1)) + y
	r = utils.genStr(newX, posDigit)..utils.genStr(newY, posDigit)
	skynet.call("redis", "lua", "set", "P", client_id, r)
end

return attr