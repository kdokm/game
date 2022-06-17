local skynet = require "skynet"
require "skynet.manager"
local socket = require "skynet.socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
local utils = require "utils"

local CMD = {}
grids = {}
updates = {}
attrs = {}
fds = {}
services = {}
local time = 0
local real_time
local rowSize = 100

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
	res.ranges = attrs[id].ranges
	res.updates = r
	res.time = time

	if attrs[id].type == "player" then
		send_package(fds[id], send_request("push", res))
	else
		skynet.call(services[id], "lua", "react", res)
	end
	updates[id] = {}
	attrs[id].ranges = {}
end

local function getGridIndex(x, y)
	return x // 5 + y // 5 * rowSize;
end

local function updateOneGrid(id, grid, init)
	if grid ~= nil then
		for k, v in pairs(grid) do
			updates[k][id] = id
			if init ~= nil then
				updates[id][k] = k
			end
		end
	end
end

local function changeGrid(id, old, new)
	if old == nil then
		if grids[new] == nil then
			grids[new] = {}
		end
		grids[new][id] = id
		for i = -1, 1 do
			for j = -rowSize, rowSize, rowSize do
				updateOneGrid(id, grids[new+i+j], true)
			end
		end
	else
		grids[old][id] = nil
		if new ~= nil then
			if grids[new] == nil then
				grids[new] = {}
			end
			grids[new][id] = id
			local diff = new - old
			if diff % rowSize == 0 then
				for i = -1, 1 do
					updateOneGrid(id, grids[new+diff+i], true)
				end
			else
				for i = -rowSize, rowSize, rowSize do
					updateOneGrid(id, grids[new+diff+i], true)
				end
			end
		end
	end
end

function CMD.init(id, attr, info)
	attrs[id] = attr
	attrs[id].id = id
	attrs[id].ranges = {}
	if attrs[id].type == "player" then
		fds[id] = info
	else
		services[id] = info
	end
	updates[id] = {}
	changeGrid(id, nil, getGridIndex(attr.x, attr.y))
end

function CMD.move(id, x, y, dir)
	local old = getGridIndex(attrs[id].x, attrs[id].y)
	local new = getGridIndex(x, y)
	attrs[id].x = x
	attrs[id].y = y
	attrs[id].dir = dir
	for i = -1, 1 do
		for j = -rowSize, rowSize, rowSize do
			updateOneGrid(id, grids[new+i+j])
		end
	end
	if old ~= new then
		changeGrid(id, old, new)
	end
end

function CMD.attack(id, type, x, y)
	local r = {}
	local index = getGridIndex(attrs[id].x, attrs[id].y)
	for i = -1, 1 do
		for j = -rowSize, rowSize, rowSize do
			local grid = grids[index+i+j]
			if grid ~= nil then
				for k, v in pairs(grid) do
					if k ~= id then
						table.insert(attrs[k].ranges, utils.getRangeSquare(x, y, 1))
						if attrs[k].type == type 
						and utils.inRangeSquare(x, y, attrs[k].x, attrs[k].y, 1) then
							r[k] = k
						end
					end
				end
			end
		end
	end
	return r
end

function CMD.updateHP(info)
	for k, v in pairs(info) do
		attrs[k].hp = v
		local index = getGridIndex(attrs[k].x, attrs[k].y)
		for i = -1, 1 do
			for j = -rowSize, rowSize, rowSize do
				updateOneGrid(k, grids[index+i+j])
			end
		end
	end
end

function CMD.quit(id)
	local fd = fds[id]
	changeGrid(id, getGridIndex(attrs[id].x, attrs[id].y), nil)
	updates[id] = nil
	attrs[id] = nil
	fds[id] = nil
	return fd
end

local function pushAll()
	for k, v in pairs(updates) do
		if next(v) ~= nil or next(attrs[k].ranges) ~= nil then
			push(k)
		end
	end
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)

	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))
	skynet.fork(function()
		while true do
			real_time = skynet.now()
			pushAll()
			local diff = 10-(skynet.now()-real_time)
			if diff > 0 then
				skynet.sleep(diff)
			end
			time = time + 1
		end
	end)
end)