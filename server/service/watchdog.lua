local skynet = require "skynet"
local cluster = require "skynet.cluster"
local sock = require "socket"

local CMD = {}
local SOCKET = {}
local agent = {}
local gate

function SOCKET.open(fd, addr)
                id = "test"
	skynet.error("New client from : " .. addr)
	skynet.call(gate, "lua", "accept" , fd)
end

local function close_agent(fd)
	local a = agent[fd]
	if a then
		agent[fd] = nil
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
	local ret, id = cluster.call("global", ".login", "open", string.sub(msg, 2), string.sub(msg, 1, 1))
	sock.send_package(fd, ret)
	if id ~= nil then
		agent[fd] = skynet.newservice("agent")
		skynet.call(agent[fd], "lua", "start", { gate = gate, watchdog = skynet.self(), fd = fd, id = id })
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

	gate = skynet.newservice("gate")
end)
