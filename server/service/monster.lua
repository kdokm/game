local skynet = require "skynet"
require "skynet.manager"

local CMD = {}

function CMD.react()
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
	skynet.register "monster"
	skynet.call("scene", "lua", "initMonster", "wolf", {})
end)