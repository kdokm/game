local skynet = require "skynet"
local equation = require "equation"

local panel = {}
local client_id
local posDigit = 3

function panel.init(id)
	client_id = id
end

local function addDetail(attrs, equips)
	local detail = equation.calDetail(attrs, equips)
	for k, v in pairs(detail) do
		attrs[k] = v
	end
	return attrs
end

function panel.getAttr(equips)
	skynet.error("get attr info")
	local r = skynet.call("redis", "lua", "hgetall", "A", client_id)
	r["free"] = equation.calFreeAttrs(r)
	r = addDetail(r, equips)
	return r
end

function panel.updateAttr(attrs)
	for k, v in pairs(attrs) do
		skynet.call("redis", "lua", "hset", "A", client_id, k, v)
	end
end

function panel.getSkill()
end

function panel.updateSkill()
end

function panel.getPos()
	local r = skynet.call("redis", "lua", "get", "P", client_id)
	return r
end

function panel.move(command)
	local r = getPos()
	local x = tonumber(string.sub(command, 1, posDigit)) + tonumber(string.sub(command, 1, 1))
	local y = tonumber(string.sub(command, posDigit+1)) + tonumber(string.sub(command, 2, 2))
	assert(x ~= nil and y ~= nil, "bad command")
	r = utils.genStr(x, posDigit)..utils.genStr(y, posDigit)
	skynet.call("redis", "lua", "set", "P", client_id, r)
end

return panel