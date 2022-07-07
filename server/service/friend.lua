local skynet = require "skynet"
local CMD = {}

function CMD.get_friends(id)
	local friends = skynet.call("redis", "lua", "zall", "F", id, true)
end

function CMD.add_friend(id1, id2)
	local score = os.time()
	skynet.call("redis", "lua", "zadd", "F", id1, score, id2)
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
	skynet.register "friend"
end)