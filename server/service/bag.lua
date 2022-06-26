local skynet = require "skynet"
local utils = require "utils"
local grade = require "grade"
local attach = require "attach"

local bag = {items, coin}
local bag_size = 30
local pos_end = 3
local amount_end = 6
local client_id

local pos = {}
local next_pos = -1
local equip_num = 4
local max_pos = bag_size + equipNum

local function cal_next_pos()
	local p = table.remove(pos)
	if p > equip_num then
		next_pos = p
	end
	table.insert(pos, p)
end

local function empty_pos(p)
	table.insert(pos, p, p)
	table.sort(pos)
	if p > next_pos then
		next_pos = p
	end
end

local function occupy_pos(p)
	table.remove(pos, p)
	if p == next_pos then
		cal_next_pos()
	end
end

function bag.init(id)
	client_id = id
	--local r = skynet.call("mongo")

	for i=1, max_pos do
		empty_pos(i)
	end

	for k, v in pairs(b) do
		local p = tonumber(string.sub(v, 1, posEnd))
		occupy_pos(p)
		if p <= 4 then
			table.insert(r, p, k)
		end
	end
	cal_next_pos()
	return r
end

function bag.move_item(id, new_pos)
	assert(pos[new_pos] == nil, "new position is not empty!")
	local r = skynet.call("redis", "lua", "hget", "B", client_id, id)
	assert(r ~= nil, "nothing to move!")

	local p = string.sub(r, 1, pos_end)
	r = utils.gen_str(new_pos, 1, pos_end)..string.sub(r, pos_end+1)
	skynet.call("redis", "lua", "hset", "B", client_id, id, r)
	occupy_pos(new_pos)
	empty_pos(p)
end

function bag.exchange_item(id1, id2)
	local r1 = skynet.call("redis", "lua", "hget", "B", client_id, id1)
	local r2 = skynet.call("redis", "lua", "hget", "B", client_id, id2)
	local p1 = string.sub(r2, 1, pos_end)
	local p2 = string.sub(r1, 1, pos_end)

	r1 = p1..string.sub(r, pos_end+1)
	r2 = p2..string.sub(r, pos_end+1)
	skynet.call("redis", "lua", "hset", "B", client_id, id1, r1)
	skynet.call("redis", "lua", "hset", "B", client_id, id2, r2)
end

function bag.use_item(id, amount)	
	local r = skynet.call("redis", "lua", "hget", "B", client_id, id)
	assert(r ~= nil, "nothing to use!")
	val = tonumber(string.sub(r, pos_end+1, amount_end)) - amount
	assert(val >= 0, "no enough item!")

	if val == 0 then
		skynet.call("redis", "lua", "hdel", "B", client_id, id)
		empty_pos(tonumber(string.sub(r, 1, pos_end)))
	else
		r = string.sub(r, 1, posEnd)..utils.gen_str(val, amount_end-pos_end)..string.sub(r, amount_end+1)
		skynet.call("redis", "lua", "hset", "B", client_id, id, r)
                end
end

local function new_item(id, amount)
                skynet.error("create new bag item")
	local str = utils.gen_str(next_pos, pos_end)..utils.gen_str(amount, amount_end-pos_end)
	skynet.call("redis", "lua", "hset", "B", client_id, id, str)
end

function bag.acq_item(id, amount)
	if next_pos == -1 then
		return false
	end
	
	local r = skynet.call("redis", "lua", "hget", "B", client_id, id)
	if r == nil then
		new_item(id, amount)
	else 
		val = tonumber(string.sub(r, pos_end+1, amount_end)) + amount
		assert(val <= 999, "cannot get more item!") 
		r = string.sub(r, 1, pos_end)..utils.gen_str(val)..string.sub(r, amount_end+1)
		skynet.call("redis", "lua", "hset", "B", client_id, id, r)
                end
	return true
end

local function gen_grade()
	local rand = math.random()
	for k, v in pairs(grade) do
		skynet.error(k)
		if rand < v["rate"] then
			return string.sub(k, 1, 1)
		else
			skynet.error(rand)
			skynet.error(v["rate"])
			rand = rand - v["rate"]
		end
	end
	return gen_grade()
end

local function gen_attach()
	local res
	local rand = math.random() * 4
	for i=1, rand do
		local rand2 = math.ceil(math.random() * #attach)
		local rand3 = math.random() * (attach[rand2].max - attach[rand2].min)
		res = res..string.sub(attach[rand2].attr,1,attach["attr_digit"]) + utils.genStr(rand3, attach["val_digit"])
	end
	return res
end

function bag.acq_equip(id, amount)
	if next_pos == -1 then
		return false
	end

	for i=1, amount do
		local grade = gen_grade()
		id = id..grade
		local attach = gen_attach()
		while (skynet.call("redis", "lua", "hget", "B", client_id, id..attach) ~= nil) do
			attach = gen_attach()
		end
		id = id..attach

		if grade == "p" or grade == "o" then
			skynet.call("redis", "lua", "hsetInst", "B", client_id, id, utils.genStr(nextPos, posEnd))
		else
			skynet.call("redis", "lua", "hset", "B", client_id, id, utils.genStr(nextPos, posEnd))
		end
		occupy_pos(next_pos)
	end
	return true
end

return bag