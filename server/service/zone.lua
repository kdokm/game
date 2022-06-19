local skynet = require "skynet"
require "skynet.manager"
local equation = require "equation"
local utils = require "utils"

local CMD = {}
local entities = {}
local monster_services = {}
local zone_id
local aoi

local function storePos(id)
	local r = utils.genStr(entities[id].x, utils.pos_digit)
	            ..utils.genStr(entities[id].y, utils.pos_digit)
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

function CMD.start(id)
	zone_id = id
	skynet.error(zone_id)
	for k, v in pairs(utils.getMonsters(id)) do
		for i = 1, v do
			local monster_id = k..tostring(i)
			monster_services[monster_id] = skynet.newservice(k)
			skynet.call(monster_services[monster_id], "lua", "start", skynet.self(), monster_id)
		end
	end
end

function CMD.initPlayer(id, fd, attr)
	entities[id] = attr
	entities[id].type = "player"
	if entities[id].dir == nil then
		entities[id].dir = utils.getInitDir()
		initHP(id)
		initMP(id)
	end
	skynet.call(aoi, "lua", "init", id, entities[id], fd)
end

function CMD.initMonster(id, info)
	entities[id] = { type="monster" }
	entities[id].hp = 300
	entities[id].x, entities[id].y = utils.initPos(zone_id, "random")
	entities[id].dir = utils.getInitDir()
	skynet.error(entities[id].x, entities[id].y)
	skynet.call(aoi, "lua", "init", id, entities[id], monster_services[id])
end

function CMD.quit(id, next)
	if next == nil and entities[id].type == "player" then
		storeHP(id)
		storeMP(id)
		storePos(id)
	end
	local fd = skynet.call(aoi, "lua", "quit", id)
	local next_zone = skynet.call("world", "lua", "updateZone", id, fd, entities[id], zone_id, next)
	entities[id] = nil
	return next_zone
end

function CMD.move(id, dir)
	local x, y = utils.decodeDir(dir)
	entities[id].x = entities[id].x + x
	entities[id].y = entities[id].y + y
	entities[id].dir = dir
	local next = utils.getZoneID(entities[id].x, entities[id].y)
	if next == zone_id then
		skynet.call(aoi, "lua", "move", id, entities[id].x, entities[id].y, entities[id].dir)
	else
		local next_zone = CMD.quit(id, next)
		return next_zone
	end
end

local function timeout(t, f, args)
	local function fWithArgs()
		f(table.unpack(args))
	end
	if args ~= nil then
		skynet.timeout(t, fWithArgs)
	else
		skynet.timeout(t, f)
	end
end

local function revive(id)
	local hp = equation.getInitHP()
	local r = {}
	r[id] = hp
	entities[id].hp = hp
	skynet.call(aoi, "lua", "updateHP", r)
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
		local amount = 50
		if entities[k].hp == 0 then
			r[k] = nil
		else
			if entities[k].hp > amount then
				entities[k].hp = entities[k].hp - amount
			else
				entities[k].hp = 0
				if entities[k].type == "player" then
					timeout(500, revive, {k})
				else
					CMD.quit(k)
					CMD.initMonster(k)
				end
			end
			r[k] = entities[k].hp
		end
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
end)