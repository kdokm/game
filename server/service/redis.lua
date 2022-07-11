local skynet = require "skynet"
local redis = require "skynet.db.redis"
require "skynet.manager"
local CMD = {}
local db

function CMD.get(col, key, name)
	if db:exists(col..key) == 0 then
		local r = skynet.call("mongo", "lua", "get", col, key, name)
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
	if option ~= nil then
		return db:set(col..key, value, option)
	else
		return db:set(col..key, value)
	end
end

function CMD.hget(col, key, field)
	skynet.error("hget")
	if db:hexists(col..key, field) == 0 then
		local r = skynet.call("mongo", "lua", "get", col, key, field)
		skynet.error(r)
		if r == nil then
			return
                                end
		db:hset(col..key, field, r)
		return r
                end
	return db:hget(col..key, field)
end

function CMD.hgetall(col, key)
	skynet.error("hgetall")
	if db:exists(col..key) == 0 then
		local r = skynet.call("mongo", "lua", "getall", col, key)
		if r == nil then
			return
                                end
		db:hset(col..key, field, r)
		return r
                end
	return db:hgetall(col..key)
end

function CMD.hset(col, key, list)
	skynet.error("hset")
	return db:hset(col..key, table.unpack(list))
	--skynet.call("mongo", "lua", "set", col, key, list)
end

function CMD.hdel(col, key, field)
	skynet.error("hdel")
	return db:hdel(col..key, field)
	--skynet.call("mongo", "lua", "del", col, key, field)
end

function CMD.zscore(col, key, member)
	skynet.error("zscore", col..key, member)
	return db:zscore(col..key, member)
end

function CMD.zrange(col, key, min, max, option)
	skynet.error("zrange", col..key)
	return db:zrange(col..key, min, max, option)
end

function CMD.zadd(col, key, score, member, option)
	skynet.error("zadd", col..key, member, score)
	if option ~= nil then
		return db:zadd(col..key, option, score, member)
	else
		return db:zadd(col..key, score, member)
	end
end

function CMD.zrem(col, key, member)
	skynet.error("zrem")
	return db:zrem(col..key, member)
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