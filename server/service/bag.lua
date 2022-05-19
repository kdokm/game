local skynet = require "skynet"
local utils = require "utils"
local grade = require "grade"
local attach = require "attach"

local bag = {}
local posEnd = 3
local amountEnd = 6
local client_id

local pos = {}
local nextPos = -1
local equipNum = 4
local maxPos = 500+equipNum

local function calNextPos()
	local p = table.remove(pos)
	if p > equipNum then
		nextPos = p
	end
	table.insert(pos, p)
end

local function emptyPos(p)
	table.insert(pos, p, p)
	table.sort(pos)
	if p > nextPos then
		nextPos = p
	end
end

local function occupyPos(p)
	table.remove(pos, p)
	if p == nextPos then
		calNextPos()
	end
end

function bag.init(id)
	local r = {}
	client_id = id
	local b = bag.get()

	for i=1, maxPos do
		emptyPos(i)
	end

	for k, v in pairs(b) do
		local p = tonumber(string.sub(v, 1, posEnd))
		occupyPos(p)
		if p <= 4 then
			table.insert(r, p, k)
		end
	end
	calNextPos()
	return r
end

function bag.get()
	local r = skynet.call("redis", "lua", "hgetall", "B", client_id)
	return r
end

function bag.moveItem(id, newPos)
	assert(pos[newPos] == nil, "new position is not empty!")
	local r = skynet.call("redis", "lua", "hget", "B", client_id, id)
	assert(r ~= nil, "nothing to move!")

	local p = string.sub(r, 1, posEnd)
	r = utils.genStr(newPos, 1, posEnd)..string.sub(r, posEnd+1)
	skynet.call("redis", "lua", "hset", "B", client_id, id, r)
	occupyPos(newPos)
	emptyPos(p)
end

function bag.exchangeItem(id1, id2)
	local r1 = skynet.call("redis", "lua", "hget", "B", client_id, id1)
	local r2 = skynet.call("redis", "lua", "hget", "B", client_id, id2)
	local p1 = string.sub(r2, 1, posEnd)
	local p2 = string.sub(r1, 1, posEnd)

	r1 = p1..string.sub(r, posEnd+1)
	r2 = p2..string.sub(r, posEnd+1)
	skynet.call("redis", "lua", "hset", "B", client_id, id1, r1)
	skynet.call("redis", "lua", "hset", "B", client_id, id2, r2)
end

function bag.useItem(id, amount)	
	local r = skynet.call("redis", "lua", "hget", "B", client_id, id)
	assert(r ~= nil, "nothing to use!")
	val = tonumber(string.sub(r, posEnd+1, amountEnd)) - amount
	assert(val >= 0, "no enough item!")

	if val == 0 then
		skynet.call("redis", "lua", "hdel", "B", client_id, id)
		emptyPos(tonumber(string.sub(r, 1, posEnd)))
	else
		r = string.sub(r, 1, posEnd)..utils.genStr(val, amountEnd-posEnd)..string.sub(r, amountEnd+1)
		skynet.call("redis", "lua", "hset", "B", client_id, id, r)
                end
end

function bag.useCoin(id, amount)	
	local r = skynet.call("redis", "lua", "hget", "B", client_id, id)
	assert(r ~= nil, "there must be coin(s)!")

	val = tonumber(string.sub(r, 0)) - amount
	assert(val >= 0, "no enough coin!")
	r = utils.genStr(val, 9)
	skynet.call("redis", "lua", "hset", "B", client_id, id, r)
end

local function newItem(id, amount)
                skynet.error("create new bag item")
	local str = utils.genStr(nextPos, posEnd)..utils.genStr(amount, amountEnd-posEnd)
	skynet.call("redis", "lua", "hset", "B", client_id, id, str)
end

function bag.acqItem(id, amount)
	if nextPos == -1 then
		return false
	end
	
	local r = skynet.call("redis", "lua", "hget", "B", client_id, id)
	if r == nil then
		newItem(id, amount)
	else 
		val = tonumber(string.sub(r, posEnd+1, amountEnd)) + amount
		assert(val <= 999, "cannot get more item!") 
		r = string.sub(r, 1, posEnd)..utils.genStr(val)..string.sub(r, amountEnd+1)
		skynet.call("redis", "lua", "hset", "B", client_id, id, r)
                 end
	return true
end

local function genGrade()
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
	return genGrade()
end

local function genAttach()
	local res
	local rand = math.random() * 4
	for i=1, rand do
		local rand2 = math.ceil(math.random() * #attach)
		local rand3 = math.random() * (attach[rand2].max - attach[rand2].min)
		res = res..string.sub(attach[rand2].attr,1,attach["attrDigit"]) + utils.genStr(rand3, attach["valDigit"])
	end
	return res
end

function bag.acqEquip(id, amount)
	if nextPos == -1 then
		return false
	end

	for i=1, amount do
		local grade = genGrade()
		id = id..grade
		local attach = genAttach()
		while (skynet.call("redis", "lua", "hget", "B", client_id, id..attach) ~= nil) do
			attach = genAttach()
		end
		id = id..attach

		if grade == "p" or grade == "o" then
			skynet.call("redis", "lua", "hsetInst", "B", client_id, id, utils.genStr(nextPos, posEnd))
		else
			skynet.call("redis", "lua", "hset", "B", client_id, id, utils.genStr(nextPos, posEnd))
		end
		occupyPos(nextPos)
	end
	return true
end

function bag.acqCoin(id, amount)
	local r = skynet.call("redis", "lua", "hget", "B", client_id, id)
	assert(r ~= nil, "user must have coin attr!")

	val = tonumber(string.sub(r, 0)) + amount
	assert(val <= 999999999, "cannot get more coins!") 
	r = utils.genStr(val, 9)

	if string.find(id, "paid") == nil and amount >= 10000 then
		skynet.call("redis", "lua", "hsetInst", "B", client_id, id, amount)
	else
		skynet.call("redis", "lua", "hset", "B", client_id, id, amount)
	end
	return amount
end

return bag