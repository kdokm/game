local skynet = require "skynet"
local mongo = require "skynet.db.mongo"
require "skynet.manager"
local db
local CMD = {}

function CMD.get(col, key, field)
	skynet.error("mongo get")
	ret = db[col]:findOne({_id = key})
	if ret == nil then
		return
	end
	return ret[field]
end

function CMD.getall(col, key)
	skynet.error("mongo getall")
	ret = db[col]:findOne({_id = key})
	if ret == nil then
		return
	end
	return ret
end

function CMD.set(col, key, list, option)
	skynet.error("mongo set")
	if option == "nx" then
		list._id = key
		return db[col]:safe_insert(list)
	else
		local op = {}
		op["$set"] = list
		return db[col]:safe_update({_id = key}, op, true)
	end
end

function CMD.del(col, key, field)
	skynet.error("mongo del")
	if field ~= nil then
		local t = {}
		t[field] = ""
		local op = {}
		op["$unset"] = t
		return db[col]:safe_update({_id = key}, op)
	else
		return db[col]:safe_delete({_id = key})
	end
end

skynet.start(function()
	local c = mongo.client(
		{
			host = "127.0.0.1",
			port = 27017,
		}
	)
	db = c["game"]
	skynet.error("start mongodb")
	skynet.dispatch("lua", function(_,_,cmd,...)
		local f = CMD[cmd]
		assert(f)
		skynet.ret(skynet.pack(f(...)))
	end)
	skynet.register ".mongo"
end)