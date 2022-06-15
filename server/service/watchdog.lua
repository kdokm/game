local skynet = require "skynet"

local CMD = {}
local SOCKET = {}
local gate
local agent = {}
local login

function SOCKET.open(fd, addr)
                id = "test"
	skynet.error("New client from : " .. addr)
	skynet.call(gate, "lua", "accept" , fd)
	--agent[fd] = skynet.newservice("agent")
	--skynet.call(agent[fd], "lua", "start", { gate = gate, watchdog = skynet.self(), fd = fd, id = id })
end

local function close_agent(fd)
	local a = agent[fd]
	agent[fd] = nil
	if a then
		skynet.call(gate, "lua", "kick", fd)
		-- disconnect never return
		skynet.send(a, "lua", "disconnect")
	end
end

function SOCKET.close(fd)
	print("socket close",fd)
	close_agent(fd)
end

function SOCKET.error(fd, msg)
	print("socket error",fd, msg)
	close_agent(fd)
end

function SOCKET.warning(fd, size)
	-- size K bytes havn't send out in fd
	print("socket warning", fd, size)
end

function SOCKET.data(fd, msg)
	skynet.error("catch data: "..msg)
	assert(string.sub(msg, 1, 1) == "C" or string.sub(msg, 1, 1) == "V", "invalid data")
	local r = skynet.call(login, "lua", "open", fd, string.sub(msg, 2), string.sub(msg, 1, 1))

	if r ~= nil then
		agent[fd] = r
	end
end

function CMD.start(conf)
	skynet.call(gate, "lua", "open" , conf)
end

function CMD.close(fd)
	close_agent(fd)
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			skynet.error("receive socket: "..subcmd)
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)

	skynet.newservice("world")
	gate = skynet.newservice("gate")
	login = skynet.newservice("login")
	skynet.call(login, "lua", "start", { gate = gate, watchdog = skynet.self() })
end)
