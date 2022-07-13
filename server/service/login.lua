local skynet = require "skynet"
require "skynet.manager"

local CMD = {}

function CMD.open(msg, flag)
	local i, j = string.find(msg, "\n")
	if i == nil or i == 1 or i == string.len(msg) then
		return
	end
	local id = string.sub(msg, 1, i-1)
	local password = string.sub(msg, i+1)
	skynet.error("id: "..id)
	skynet.error("password: "..password)

	if flag == "V" then
		local ret = skynet.call("redis", "lua", "get", "S", id, "password")
		if ret ~= password then
			return "wrong password"
		end
	else
		local ret = skynet.call("redis", "lua", "set", "S", id, "password", password, "nx")
		if ret == nil then
			return "user ID already exists"
		end
	end
	return "ok", id
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
	skynet.register ".login"
end)