local skynet = require "skynet"
local utils = require "utils"
local equip = require "equip"

local bag = {items = {}, coin}
local items_limit = 999
local pos_end = 3
local amount_end = 6
local client_id
local updates = {}

local grids = {}
local total = 0
local equip_num = 4
local next_pos = equip_num + 1
local max_pos = utils.bag_size + equip_num

local function cal_next_pos()
	for i = next_pos+1, utils.bag_size do
		if grids[i] == nil then
			next_pos = i
			return
		end
	end
	next_pos = -1
end

local function empty_pos(p)
	grids[p] = nil
	if p > equip_num then
		total = total - 1
		if p < next_pos then
			next_pos = p
		end
	end
end

local function occupy_pos(p, id)
	grids[p] = id
	if p > equip_num then
		total = total + 1
		if p == next_pos then
			cal_next_pos()
		end
	end
end

function bag.init(id)
	client_id = id
	local r = skynet.call("mongo", "lua", "getall", "B", client_id)
	if r == nil then
		return
	end
	for k, v in pairs(r) do
		if k == "coin" then
			bag.coin = v
		elseif k ~= "_id" then
			local pos =  tonumber(string.sub(v, 1, pos_end))
			local amount = tonumber(string.sub(v, pos_end+1))
			bag.items[k] = {id = k, pos = pos, amount = amount}
			occupy_pos(pos, k)
		end
	end
end

local function update(id)
	table.insert(updates, id)
end

local function exchange_items(id1, id2)
	local temp = bag.items[id1].pos
	bag.items[id1].pos = bag.items[id2].pos
	bag.items[id2].pos = temp
	grids[bag.items[id1].pos] = id1
	grids[bag.items[id2].pos] = id2
	table.insert(updates, id1)
	table.insert(updates, id2)
end

function bag.move_item(id, new_pos)
	if grids[new_pos] ~= nil then
		exchange_items(id, grids[new_pos])
	else
		empty_pos(bag.items[id].pos)
		bag.items[id].pos = new_pos
		occupy_pos(new_pos, id)
		table.insert(updates, id)
	end
end

function bag.use_item(id, amount)
	local val = bag.items[id].amount - amount
	if val < 0 then
		return "no enough item!"
	elseif val == 0 then
		empty_pos(bag.items[id].pos)
		bag.items[id] = nil
	else
		bag.items[id].amount = val
                end
	table.insert(updates, id)
end

local function new_item(id, amount)
                skynet.error("create new bag item")
	local str = utils.gen_str(next_pos, pos_end)..utils.gen_str(amount, amount_end-pos_end)
	skynet.call("redis", "lua", "hset", "B", client_id, id, str)
end

function bag.check_full()
	if next_pos == -1 then
		return "your bag is full!"
	else
		local remain = utils.bag_size - total
		if remain < 5 then
			return "your bag has only "..remain.." spaces left!)"
		end
	end
end

function bag.acq_item(id, amount)
	local msg
	if bag.items[id] == nil then
		if next_pos == -1 then
			return
		end
		bag.items[id] = {id = id, pos = next_pos, amount = amount}
		occupy_pos(next_pos, id)
		msg = "got "..amount.." "..id.."(s)!"
	else
		if bag.items[id].amount == items_limit then
			return
		end
		local val = bag.items[id].amount + amount
		msg = "got "..val-bag.items[id].amount.." "..id.."(s)!"
		if val <= items_limit then
			bag.items[id].amount = val
		else
			bag.items[id].amount = items_limit
			msg = msg.." (cannot get more than "..items_limit.." of "..id.."!)"
		end
                end
	table.insert(updates, id)
	return msg
end

function bag.acq_equip(id, amount)
	for i=1, amount do
		if next_pos == -1 then
			skynet.error("bag full")
			if i == 1 then
				return
			else
				return "got "..(i-1).." "..equip.get_name(id).."(s)!"
			end
		end
		local grade = equip.gen_grade()
		local attach = equip.gen_attach()
		while bag.items[equip.gen_id(id, grade, attach)] ~= nil do
			attach = equip.gen_attach()
		end
		id = equip.gen_id(id, grade, attach)

		if grade == "p" or grade == "o" then
			--skynet.call("mongo", "lua", "set", "B", client_id, id, utils.genStr(nextPos, posEnd))
		else
			table.insert(updates, id)
		end
		bag.items[id] = {id = id, pos = next_pos, amount = 1}
		occupy_pos(next_pos, id)
	end
	return "got "..amount.." "..equip.get_name(id).."(s)!"
end

return bag