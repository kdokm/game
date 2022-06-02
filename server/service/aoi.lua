local skynet = require "skynet"
require "skynet.manager"
local socket = require "skynet.socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"

local CMD = {}
observer = {}
observant = {}
attrs = {}
fds = {}

local function inRange(x1, y1, x2, y2)
	local d = x1 - x2
	if d > 2 or d < -2 then
		return false
	end
	d = y1 - y2
	if d > 2 or d < -2 then
		return false
	end
	return true
end

local function send_package(fd, pack)
	local package = string.pack(">s2", pack)
	socket.write(fd, package)
end

local function push(id)
	local r = {}
	for k, v in pairs(observant[id]) do
		table.insert(r, attrs[k])
	end
	attrs[id].updates = r
	send_package(fds[id], send_request("push", attrs[id]))
	attrs[id].updates = nil
end

function CMD.init(id, attr, fd)
	attrs[id] = attr
	attrs[id].id = id
	fds[id] = fd
	observer[id] = {}
	observant[id] = {}
	for k, v in pairs(observer) do
		observant[id][k] = k
	end
	for k, v in pairs(observant) do
		observer[id][k] = k
	end
	CMD.move(id, attr.x, attr.y)
	push(id)
	observant[id] = {}
end

function CMD.move(id, x, y)
	for k, v in pairs(observer) do
		v[id] = id
	end
	for k, v in pairs(observant) do
		v[id] = id
	end
	attrs[id].x = x
	attrs[id].y = y
end

function CMD.quit(id)
	observer[id] = nil
	observant[id] = nil
	for k, v in pairs(observer) do
		--todo
	end
	for k, v in pairs(observant) do
		--todo
	end
	attrs[id] = nil
	fds[id] = nil
end

local function pushAll()
	for k, v in pairs(observant) do
		push(k)
		observant[k] = {}
	end
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
	skynet.register "aoi"

	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))
	skynet.fork(function()
		while true do
			pushAll()
			skynet.sleep(50)
		end
	end)
end)