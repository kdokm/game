local skynet = require "skynet"
local equation = require "equation"
local utils = require "utils"

local attr = {}
local client_id

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

return attr