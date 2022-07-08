local skynet = require "skynet"
require "skynet.manager"
local CMD = {}

function CMD.get_friends(id)
	local friends = {}
	local res = skynet.call("redis", "lua", "zrange", "F", id, 0, 100, "withscores")
	if res ~= nil then
		for i = 1, #res, 2 do
			if res[i+1] == "1" then
				status = "friend"
			elseif res[i+1] == "2" then
				status = "pending"
			end
			table.insert(friends, {id = res[i], status = status})
		end
	end
	return friends
end

function CMD.add_friend(id1, id2)
	local res = skynet.call("redis", "lua", "zscore", "F", id1, id2)
	if res ~= nil then
		skynet.call("redis", "lua", "zadd", "F", id1, "1", id2)
		skynet.call("redis", "lua", "zadd", "F", id2, "1", id1)
	else
		skynet.call("redis", "lua", "zadd", "F", id2, "2", id1)
	end
end

function CMD.delete_friend(id1, id2)
	skynet.call("redis", "lua", "zrem", "F", id1, id2)
	skynet.call("redis", "lua", "zrem", "F", id2, id1)
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
	skynet.register "friend"
end)