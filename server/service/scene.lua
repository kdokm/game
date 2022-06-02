local skynet = require "skynet"
require "skynet.manager"
local equation = require "equation"
local utils = require "utils"

local CMD = {}
local entities = {}
local posDigit = 3

local function initPos(id)
	local r = skynet.call("redis", "lua", "get", "P", id)
	if r == nil then
		entities[id].x = 250
		entities[id].y = 50
	else
		entities[id].x = tonumber(string.sub(r, 1, posDigit))
                                entities[id].y = tonumber(string.sub(r, posDigit+1))
	end
end

local function storePos(id)
	local r = utils.genStr(entities[id].x, posDigit)..utils.genStr(entities[id].y, posDigit)
	skynet.call("redis", "lua", "set", "P", id, r)
end

local function initHP(id)
	local r = skynet.call("redis", "lua", "get", "H", id)
	if r == nil then
		entities[id].hp = equation.getInitHP()
	else
		entities[id].hp = tonumber(r)
	end
end

local function storeHP(id)
	skynet.call("redis", "lua", "set", "H", id, tostring(entities[id].hp))
end

local function initMP(id)
	local r = skynet.call("redis", "lua", "get", "M", id)
	if r == nil then
		entities[id].mp = equation.getInitMP()
	else
		entities[id].mp = tonumber(r)
	end
end

local function storeMP(id)
	skynet.call("redis", "lua", "set", "M", id, tostring(entities[id].mp))
end

function CMD.initPlayer(id, fd)
	entities[id] = { type="player" }
	initHP(id)
	initMP(id)
	initPos(id)
	skynet.call("aoi", "lua", "init", id, entities[id], fd)
end

function CMD.initMonster(id, info)
	entities[id] = { type="monster" }
	entities[id].hp = 300
	entities[id].x = 200 + math.ceil(math.random() * 100)
	entities[id].y = 40 + math.ceil(math.random() * 20)
	skynet.error(entities[id].x, entities[id].y)
	skynet.call("aoi", "lua", "init", id, entities[id], nil)
end

function CMD.quit(id)
	storeHP(id)
	storeMP(id)
	storePos(id)
	entities[id] = nil
	skynet.call("aoi", "lua", "quit", id)
end

function CMD.move(id, x, y)
	entities[id].x = entities[id].x + x
	entities[id].y = entities[id].y + y
	skynet.call("aoi", "lua", "move", id, entities[id].x, entities[id].y)
end

function CMD.attack(id)
	local r = skynet.call("aoi", "lua", "attack", id, "monster")
	for k, v in pairs(r) do
		local amount = 100
		if entities[k].hp > amount then
			entities[k].hp = entities[k].hp - amount
		else
			entities[k].hp = 0
		end
		r[k] = entities[k].hp
		skynet.error(r[k])
	end
	skynet.call("aoi", "lua", "updateHP", r)
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
	skynet.register "scene"
	skynet.newservice("aoi")
	skynet.newservice("monster")
end)