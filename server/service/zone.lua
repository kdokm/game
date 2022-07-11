local skynet = require "skynet"
local equation = require "equation"
local attr = require "attr"
local utils = require "utils"
local socket = require "socket"
local equip = require "equip"

local CMD = {}
local entities = {}
local monster_services = {}
local detail_attrs = {}
local status = {}
local damage = {}
local injury = {}
local zone_id
local aoi

local function init_status(id)
	entities[id].hp = equation.get_init_hp()
	entities[id].mp = equation.get_init_mp()
	entities[id].dir = utils.get_init_dir()
	entities[id].exp = 0
end

local function store_status(id)
	local list = {hp = entities[id].hp, mp = entities[id].mp, exp = entities[id].exp, 
		   x = entities[id].x, y = entities[id].y, dir = entities[id].dir}
	skynet.call("mongo", "lua", "set", "S", id, list)
end

function CMD.start(id)
	zone_id = id
	skynet.error(zone_id)
	for k, v in pairs(utils.get_monsters(id)) do
		for i = 1, v do
			local monster_id = k..tostring(i)
			monster_services[monster_id] = skynet.newservice(k)
			skynet.call(monster_services[monster_id], "lua", "start", skynet.self(), monster_id)
		end
	end
end

function CMD.init_player(id, info, detail_attr)
	entities[id] = info
	entities[id].type = "player"
	if entities[id].exp == nil then
		init_status(id)
	end
	if s == nil then
		local a = attr.get_attr(id)
		detail_attrs[id] = equation.cal_detail(a, {})
		detail_attrs[id].level = a.level
	else
		detail_attrs[id] = detail_attr
	end
	skynet.call(aoi, "lua", "init", id, entities[id])
	local content = {level = detail_attrs[id].level, exp = entities[id].exp}
	socket.send_package(entities[id].fd, socket.send_request("drop", content))
end

function CMD.init_monster(id, detail_attr)
	entities[id] = { type="monster" }
	entities[id].hp = detail_attr.hp
	entities[id].x, entities[id].y = utils.init_pos(zone_id, "random")
	entities[id].dir = utils.get_init_dir()
	skynet.error(entities[id].x, entities[id].y)
	detail_attrs[id] = detail_attr
	damage[id] = {}
	injury[id] = {}
	skynet.call(aoi, "lua", "init", id, entities[id], monster_services[id])
end

function CMD.update_detail_attr(id, e)
	local d = equation.cal_detail(attr.get_attr(id), e)
	for k, v in pairs(d) do
		detail_attrs[id][k] = v
	end
end

local function cal_portion(data, portion)
	local sum = utils.sum(data)
	if sum ~= 0 then
		for k, v in pairs(data) do
			portion[k] = (portion[k] or 0) + v / sum
		end
	else
		for k, v in pairs(portion) do
			portion[k] = portion[k] + 1 / #portion
		end
	end
	return portion
end

local function drop(id)
	local portion = {}
	cal_portion(damage[id], portion)
	cal_portion(injury[id], portion)
	local total = detail_attrs[id].exp
	for k, v in pairs(portion) do
		if entities[k] ~= nil then
			local level
			local gain = math.min(total * v // 2, total)
			level, entities[k].exp = equation.cal_level_exp(detail_attrs[k].level, entities[k].exp, gain)
			if level ~= detail_attrs[k].level then
				attr.update_attr(k, {level = level})
				detail_attrs[k].level = level
			end
			local items = {}
			equip.generate(detail_attrs[id].max_level, detail_attrs[id].max_amount, items)
			skynet.call(entities[k].agent, "lua", "drop", detail_attrs[k].level, entities[k].exp, items)
		end
	end
end

function CMD.quit(id, next)
	local next_zone
	if entities[id].type == "player" then
		if next == nil then 
			store_status(id)
		end
		next_zone = skynet.call("world", "lua", "update_zone", id, entities[id], detail_attrs[id], zone_id, next)
		detail_attrs[id] = nil
	else
		drop(id)
		damage[id] = nil
		injury[id] = nil
	end
	skynet.call(aoi, "lua", "quit", id)
	entities[id] = nil
	return next_zone
end

function CMD.move(id, dir)
	local x, y = utils.decode_dir(dir)
	entities[id].x = entities[id].x + x
	entities[id].y = entities[id].y + y
	entities[id].dir = dir
	local next = utils.get_zone_id(entities[id].x, entities[id].y)
	if next == zone_id then
		skynet.call(aoi, "lua", "move", id, entities[id].x, entities[id].y, entities[id].dir)
	else
		local next_zone = CMD.quit(id, next)
		return next_zone
	end
end

local function timeout(t, f, args)
	local function f_with_args()
		f(table.unpack(args))
	end
	if args ~= nil then
		skynet.timeout(t, f_with_args)
	else
		skynet.timeout(t, f)
	end
end

local function revive(id)
	local hp = equation.get_init_hp()
	local r = {}
	r[id] = hp
	entities[id].hp = hp
	skynet.call(aoi, "lua", "update_hp", r)
end

function CMD.attack(id)
	local x, y = utils.decode_dir(entities[id].dir)
	local r
	if entities[id].type == "player" then
		r = skynet.call(aoi, "lua", "attack", id, "monster", entities[id].x+x, entities[id].y+y)
	else
		r = skynet.call(aoi, "lua", "attack", id, "player", entities[id].x+x, entities[id].y+y)
	end
	for k, v in pairs(r) do
		if entities[k].hp == 0 then
			r[k] = nil
		else
			local amount = equation.cal_damage(detail_attrs[id], detail_attrs[k])
			if entities[id].type == "player" then
				damage[k][id] = (damage[k][id] or 0) + amount
			else
				injury[id][k] = (injury[id][k] or 0) + amount
			end
			if entities[k].hp > amount then
				entities[k].hp = entities[k].hp - amount
			else
				entities[k].hp = 0
				if entities[k].type == "player" then
					timeout(500, revive, {k})
				else
					CMD.quit(k)
					CMD.init_monster(k, detail_attrs[k])
				end
			end
			r[k] = entities[k].hp
		end
	end
	skynet.call(aoi, "lua", "update_hp", r)
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
	aoi = skynet.newservice("aoi")
end)