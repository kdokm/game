local skynet = require "skynet"

local CMD = {}
local gate
local watchdog

function CMD.start(conf)
	gate = conf.gate
	watchdog = conf.watchdog
end

function CMD.open(fd, msg, flag)
	local i, j = string.find(msg, "\n")
	if i == nil or i == 1 or i == string.len(msg) then
		return
	end
	local id = string.sub(msg, 1, i-1)
	local password = string.sub(msg, i+1)
	skynet.error("id: "..id)
	skynet.error("password: "..password)

	if flag == "V" then
		local ret = skynet.call("mongo", "lua", "get", "A", id, "password")
		if ret ~= password then
			return
		end
	else
		--TODO: register new user
		--skynet.call("mongo", "lua", "set", "A", id, "password", password)
	end

	local agent = skynet.newservice("agent")
	skynet.call(agent, "lua", "start", { gate = gate, watchdog = watchdog, fd = fd, id = id })
	return agent
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)