local skynet = require "skynet"
require "skynet.manager"
local socket = require "skynet.socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
local utils = require "utils"

local CMD = {}
observer = {}
observant = {}
updates = {}
attrs = {}
fds = {}

local function send_package(fd, pack)
	local package = string.pack(">s2", pack)
	socket.write(fd, package)
end

local function push(id)
	local r = {}
	for k, v in pairs(updates[id]) do
		table.insert(r, attrs[k])
	end

	local res = {}
	res.x = attrs[id].x
	res.y = attrs[id].y
	res.hp = attrs[id].hp
	res.mp = attrs[id].mp
	res.updates = r

	if attrs[id].type == "player" then
		send_package(fds[id], send_request("push", res))
	else
		skynet.call("monster", "lua", "react", res)
	end
end

function CMD.init(id, attr, fd)
	attrs[id] = attr
	attrs[id].id = id
	if attrs[id].type == "player" then
		fds[id] = fd
	end
	observer[id] = {}
	observant[id] = {}
	updates[id] = {}
	for k, v in pairs(observer) do
		observant[id][k] = k
		observant[k][id] = id
	end
	for k, v in pairs(observant) do
		observer[id][k] = k
		observer[k][id] = id
	end
	CMD.move(id, attr.x, attr.y, attr.dir)
	push(id)
end

function CMD.move(id, x, y, dir)
	for k, v in pairs(attrs) do
		updates[k][id] = id
		updates[id][k] = k
	end
	attrs[id].x = x
	attrs[id].y = y
	attrs[id].dir = dir
end

function CMD.attack(id, type, x, y)
	local r = {}
	for k, v in pairs(observant[id]) do
		skynet.error(k)
		if k ~= id and attrs[k].type == type 
		and utils.inRangeSquare(x, y, attrs[k].x, attrs[k].y, 1) then
			skynet.error("in2")
			r[k] = k
		end
	end
	return r
end

function CMD.updateHP(info)
	for k, v in pairs(info) do
		attrs[k].hp = v
		for k2, v2 in pairs(observer) do
			updates[k2][k] = k
		end
	end
end

function CMD.quit(id)
	observer[id] = nil
	observant[id] = nil
	updates[id] = nil
	for k, v in pairs(observer) do
		v[id] = nil
	end
	for k, v in pairs(observant) do
		v[id] = nil
	end
	attrs[id] = nil
	fds[id] = nil
end

local function pushAll()
	for k, v in pairs(updates) do
		if next(v) ~= nil then
			push(k)
			updates[k] = {}
		end
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
			skynet.sleep(33)
		end
	end)
end)