local skynet = require "skynet"
local cluster = require "skynet.cluster"
local redis = require "skynet.db.redis"
require "skynet.manager"
local CMD = {}
local db

function CMD.get(col, key, name)
	if db:exists(col..key) == 0 then
		local r = cluster.call("db", ".mongo", "get", col, key, name)
		if r == nil then
			return
                                end
		db:set(col..key, r)
		return r
	end
	return db:get(col..key)
end

function CMD.set(col, key, name, value, option)
	skynet.error("set")
	local list = {}
	list[name] = value
	local ok, err, r = cluster.call("db", ".mongo", "set", col, key, list, option)
	if ok then
		if option ~= nil then
			db:set(col..key, value, option)
		else
			db:set(col..key, value)
		end
	else
		skynet.error(err)
	end
	return ok
end

function CMD.del(col, key)
	skynet.error("del")
	local ok, err, r = cluster.call("db", ".mongo", "del", col, key)
	if ok then
		db:getdel(col..key)
	end
	return ok
end

local function flatten(t, reverse)
	local r = {}
	for k, v in pairs(t) do
		if reverse then
			table.insert(r, v)
			table.insert(r, k)
		else
			table.insert(r, k)
			table.insert(r, v)
		end
	end
	return r
end

function CMD.hget(col, key, field)
	skynet.error("hget")
	if db:hexists(col..key, field) == 0 then
		local r = cluster.call("db", ".mongo", "getall", col, key)
		if r == nil then
			return
                                end
		db:hset(col..key, table.unpack(flatten(r, false)))
		return r[field]
                end
	return db:hget(col..key, field)
end

function CMD.hgetall(col, key)
	skynet.error("hgetall")
	if db:exists(col..key) == 0 then
		local r = cluster.call("db", ".mongo", "getall", col, key)
		if r == nil then
			return
                                end
		db:hset(col..key, table.unpack(flatten(r, false)))
                end
	return db:hgetall(col..key)
end

function CMD.hset(col, key, list)
	skynet.error("hset")
	local ok, err, r = cluster.call("db", ".mongo", "set", col, key, list)
	if ok then
		db:hset(col..key, table.unpack(flatten(list, false)))
	else
		skynet.error(err)
	end
	return ok
end

function CMD.hdel(col, key, field)
	skynet.error("hdel")
	local ok, err, r = cluster.call("db", ".mongo", "del", col, key, field)
	if ok then
		if field ~= nil then
			db:hdel(col..key, field)
		else
			local keys = db:hkeys(col..key)
			db:hdel(col..key, table.unpack(keys))
		end
	end
	return ok
end

function CMD.zscore(col, key, member)
	skynet.error("zscore", col..key, member)
	if db:zrank(col..key, member) == nil then
		local r = cluster.call("db", ".mongo", "getall", col, key)
		if r == nil then
			return
                                end
		db:zadd(col..key, table.unpack(flatten(r, true)))
		return r[member]
                end
	return db:zscore(col..key, member)
end

function CMD.zrange(col, key, min, max, option)
	skynet.error("zrange", col..key)
	if db:zcard(col..key) == 0 then
		local r = cluster.call("db", ".mongo", "getall", col, key)
		if r == nil then
			return
                                end
		db:zadd(col..key, table.unpack(flatten(r, true)))
                end
	return db:zrange(col..key, min, max, option)
end

function CMD.zadd(col, key, score, member, option)
	skynet.error("zadd", col..key, member, score)
	local list = {}
	list[member] = score
	local ok, err, r = cluster.call("db", ".mongo", "set", col, key, list)
	if ok then
		if option ~= nil then
			db:zadd(col..key, option, score, member)
		else
			db:zadd(col..key, score, member)
		end
	end
	return ok
end

function CMD.zrem(col, key, member)
	skynet.error("zrem")
	local ok, err, r = cluster.call("db", ".mongo", "del", col, key, member)
	if ok then
		db:zrem(col..key, member)
	end
	return ok
end

function CMD.eval()
end

skynet.start(function()
	db = redis.connect {
		host = "127.0.0.1",
		port = 6379,
		db = 0
	}
	skynet.error("start redis")
	skynet.dispatch("lua", function(_,_, cmd, ...)
		local f = CMD[cmd]
		assert(f)
		skynet.ret(skynet.pack(f(...)))
	end)
	skynet.register "redis"
end)