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
local damage = {}
local injury = {}
local zone_id
local aoi

local function store_pos(id)
	local r = utils.gen_str(entities[id].x, utils.pos_digit)
	            ..utils.gen_str(entities[id].y, utils.pos_digit)
	skynet.call("redis", "lua", "set", "P", id, r)
end

local function init_hp(id)
	local r = skynet.call("redis", "lua", "get", "H", id)
	if r == nil then
		entities[id].hp = equation.get_init_hp()
	else
		entities[id].hp = tonumber(r)
	end
end

local function store_hp(id)
	skynet.call("redis", "lua", "set", "H", id, tostring(entities[id].hp))
end

local function init_mp(id)
	local r = skynet.call("redis", "lua", "get", "M", id)
	if r == nil then
		entities[id].mp = equation.get_init_mp()
	else
		entities[id].mp = tonumber(r)
	end
end

local function store_mp(id)
	skynet.call("redis", "lua", "set", "M", id, tostring(entities[id].mp))
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
	if detail_attr == nil then
		entities[id].dir = utils.get_init_dir()
		init_hp(id)
		init_mp(id)
		local a = attr.get_attr(id)
		detail_attrs[id] = equation.cal_detail(a, {})
		detail_attrs[id].level = a.level
		detail_attrs[id].exp = a.exp
	else
		detail_attrs[id] = detail_attr
	end
	skynet.call(aoi, "lua", "init", id, entities[id])
	socket.send_package(entities[id].fd, socket.send_request("drop", detail_attrs[id]))
end

function CMD.init_monster(id, detail_attr)
	entities[id] = { type="monster" }
	entities[id].hp = 300
	entities[id].x, entities[id].y = utils.init_pos(zone_id, "random")
	entities[id].dir = utils.get_init_dir()
	skynet.error(entities[id].x, entities[id].y)
	detail_attrs[id] = detail_attr
	damage[id] = {}
	injury[id] = {}
	skynet.call(aoi, "lua", "init", id, entities[id], monster_services[id])
end

function CMD.update_attr(id, a)
	local d = equation.cal_detail(a, {})
	for k, v in pairs(d) do
		detail_attrs[id][k] = v
	end
end

local function cal_portion(data, portion)
	local sum = utils.sum(data)
	for k, v in pairs(data) do
		portion[k] = (portion[k] or 0) + v / sum
	end
	return portion
end

local function drop(id)
	local portion = {}
	cal_portion(damage[id], portion)
	cal_portion(injury[id], portion)
	local total = detail_attrs[id].exp
	for k, v in pairs(portion) do
		detail_attrs[k].level, detail_attrs[k].exp 
		= equation.cal_level_exp(detail_attrs[k].level, detail_attrs[k].exp, total * v // 2)
		attr.update_attr(k, {level = detail_attrs[k].level, exp = detail_attrs[k].exp})
		local items = {}
		equip.generate(detail_attrs[id].max_level, detail_attrs[id].max_amount, items)
		skynet.call(entities[k].agent, "lua", "drop", detail_attrs[k].level, detail_attrs[k].exp, items)
	end
end

function CMD.quit(id, next)
	local next_zone
	if entities[id].type == "player" then
		if next == nil then 
			store_hp(id)
			store_mp(id)
			store_pos(id)
		end
		detail_attrs[id] = nil
		next_zone = skynet.call("world", "lua", "update_zone", id, entities[id], detail_attrs[id], zone_id, next)
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