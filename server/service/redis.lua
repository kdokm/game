local skynet = require "skynet"
local redis = require "skynet.db.redis"
require "skynet.manager"
local CMD = {}
local db

function CMD.get(col, key)
	--if ~db:exists(key)
		--local r = skynet.call("mongodb", "lua", "get", self.key)
		
	--end
	return db:get(col..key)
end

function CMD.set(col, key, value)
	skynet.error("set")
	db:set(col..key, value)
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

function CMD.hset(col, key, field, value)
	skynet.error("hset")
	db:hset(col..key, field, value)
end

function CMD.hsetInst(col, key, field, value)
	skynet.error("hset (instant write back)")
	db:hset(col..key, field, value)
	--skynet.call("mongo", "lua", "set", col, key, field, value)
end

function CMD.hdel(col, key, field)
	sknet.error("hdel")
	db:hdel(col..key, field)
end

function CMD.hdelInst(col, key, field)
	skynet.error("hdel (instant write back)")
	db:hdel(col..key, field)
	--skynet.call("mongo", "lua", "del", col, key, field)
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