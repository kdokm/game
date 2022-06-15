local skynet = require "skynet"
require "skynet.manager"
local equation = require "equation"
local utils = require "utils"
local backend_utils = require "backend_utils"

local CMD = {}
local entities = {}
local zones = {}
local zone_id
local aoi
local monster

local function storePos(id)
	local r = utils.genStr(entities[id].x, backend_utils.pos_digit)
	            ..utils.genStr(entities[id].y, backend_utils.pos_digit)
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

function CMD.start(id, zs)
	zone_id = id
	skynet.error(zone_id)
	zones = zs
	skynet.call(monster, "lua", "start", skynet.self())
end

function CMD.initPlayer(id, fd, x, y)
	entities[id] = { type="player" }
	entities[id].x = x
                entities[id].y = y
	entities[id].dir = utils.getInitDir()
	initHP(id)
	initMP(id)
	skynet.call(aoi, "lua", "init", id, entities[id], fd)
end

function CMD.initMonster(id, info)
	entities[id] = { type="monster" }
	entities[id].hp = 300
	entities[id].x, entities[id].y = backend_utils.initPos(zone_id, "random")
	entities[id].dir = utils.getInitDir()
	skynet.error(entities[id].x, entities[id].y)
	skynet.call(aoi, "lua", "init", id, entities[id], monster)
end

function CMD.quit(id)
	storeHP(id)
	storeMP(id)
	storePos(id)
	entities[id] = nil
	skynet.call(aoi, "lua", "quit", id)
end

function CMD.move(id, dir)
	local x, y = utils.decodeDir(dir)
	entities[id].x = entities[id].x + x
	entities[id].y = entities[id].y + y
	entities[id].dir = dir
	skynet.call(aoi, "lua", "move", id, entities[id].x, entities[id].y, entities[id].dir)
end

function CMD.attack(id)
	local x, y = utils.decodeDir(entities[id].dir)
	local r
	if entities[id].type == "player" then
		r = skynet.call(aoi, "lua", "attack", id, "monster", entities[id].x+x, entities[id].y+y)
	else
		r = skynet.call(aoi, "lua", "attack", id, "player", entities[id].x+x, entities[id].y+y)
	end
	for k, v in pairs(r) do
		local amount = 10
		if entities[k].hp > amount then
			entities[k].hp = entities[k].hp - amount
		else
			entities[k].hp = 0
		end
		r[k] = entities[k].hp
		skynet.error(r[k])
	end
	skynet.call(aoi, "lua", "updateHP", r)
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
	aoi = skynet.newservice("aoi")
	monster = skynet.newservice("monster")
end)