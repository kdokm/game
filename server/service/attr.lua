local skynet = require "skynet"
local equation = require "equation"
local utils = require "utils"

local attr = {}
local client_id
local posDigit = 3

hp = nil

function attr.getPos()
	local r = skynet.call("redis", "lua", "get", "P", client_id)
	if r == nil then
		return nil, nil
	end
	skynet.error(r)
	local x = tonumber(string.sub(r, 1, posDigit))
	local y = tonumber(string.sub(r, posDigit+1))
	return x, y
end

local function getInitPos()
	local x, y = attr.getPos()
	if x == nil then
		x = 250
		y = 50
		local r = utils.genStr(x, posDigit)..utils.genStr(y, posDigit)
		skynet.call("redis", "lua", "set", "P", client_id, r)
	end
	return x, y
end

function attr.getCurrHP()
	local r = skynet.call("redis", "lua", "get", "H", client_id)
	if r == nil then
		return nil
	end
	return tonumber(r)
end

local function getInitHP()
	local r = attr.getCurrHP()
	if r == nil then
		r = equation.getInitHP()
		skynet.call("redis", "lua", "set", "H", client_id, tostring(r))
	end
	hp = r
	return r
end

function attr.getCurrMP()
	local r = skynet.call("redis", "lua", "get", "H", client_id)
	if r == nil then
		return nil
	end
	return tonumber(r)
end

local function getInitMP()
	local r = attr.getCurrMP()
	if r == nil then
		r = equation.getInitMP()
		skynet.call("redis", "lua", "set", "M", client_id, tostring(r))
	end
	return r
end

function attr.init(id)
	client_id = id
	local r = {}
	r.x, r.y = getInitPos()
	r.hp = getInitHP()
	r.mp = getInitMP()
	return r
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

function attr.move(x, y)
	local newX, newY = attr.getPos()
	assert(newX ~= nil)
	newX = newX + x
	newY = newY + y
	r = utils.genStr(newX, posDigit)..utils.genStr(newY, posDigit)
	skynet.call("redis", "lua", "set", "P", client_id, r)
	skynet.call("aoi", "lua", "update", client_id, newX, newY, hp)
end

return attr