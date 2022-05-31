local skynet = require "skynet"
require "skynet.manager"
local equation = require "equation"
local utils = require "utils"

local CMD = {}
local players = {}
local posDigit = 3

local function initPos(id)
	local r = skynet.call("redis", "lua", "get", "P", id)
	if r == nil then
		players[id].x = 250
		players[id].y = 50
	else
		players[id].x = tonumber(string.sub(r, 1, posDigit))
                                players[id].y = tonumber(string.sub(r, posDigit+1))
	end
end

local function storePos(id)
	local r = utils.genStr(players[id].x, posDigit)..utils.genStr(players[id].y, posDigit)
	skynet.call("redis", "lua", "set", "P", id, r)
end

local function initHP(id)
	local r = skynet.call("redis", "lua", "get", "H", id)
	if r == nil then
		players[id].hp = equation.getInitHP()
	else
		players[id].hp = tonumber(r)
	end
end

local function storeHP(id)
	skynet.call("redis", "lua", "set", "H", id, tostring(players[id].hp))
end

local function initMP(id)
	local r = skynet.call("redis", "lua", "get", "M", id)
	if r == nil then
		players[id].mp = equation.getInitMP()
	else
		players[id].mp = tonumber(r)
	end
end

local function storeMP(id)
	skynet.call("redis", "lua", "set", "M", id, tostring(players[id].mp))
end

function CMD.init(id)
	players[id] = {}
	initPos(id)
	initHP(id)
	initMP(id)
	skynet.call("aoi", "lua", "update", id, players[id].x, players[id].y, players[id].hp)
	return players[id]
end

function CMD.quit(id)
	storePos(id)
	storeHP(id)
	storeMP(id)
	skynet.call("aoi", "lua", "quit", id)
end

function CMD.move(id, x, y)
	players[id].x = players[id].x + x
	players[id].y = players[id].y + y
	skynet.call("aoi", "lua", "update", id, players[id].x, players[id].y, players[id].hp)
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
	skynet.register "scene"
end)