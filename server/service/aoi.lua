local skynet = require "skynet"
require "skynet.manager"
local utils = require "utils"
local socket = require "socket"
local equation = require "equation"

local CMD = {}
grids = {}
updates = {}
entities = {}
services = {}
local time = 0
local real_time
local row_size = 100

local function push(id)
	local r = {}
	for k, v in pairs(updates[id]) do
		if k ~= id then
			table.insert(r, entities[k])
		end
	end

	local res = {}
	res.x = entities[id].x
	res.y = entities[id].y
	res.hp = entities[id].hp
	res.mp = entities[id].mp
	res.dir = entities[id].dir
	res.ranges = entities[id].ranges
	res.updates = r
	res.time = time

	updates[id] = {}
	entities[id].ranges = {}
	if entities[id].type == "player" then
		socket.send_package(entities[id].fd, socket.send_request("push", res))
	else
		skynet.call(services[id], "lua", "react", res)
	end
end

local function get_grid_index(x, y)
	return x // 5 + y // 5 * row_size;
end

local function update_one_grid(id, grid, init)
	if grid ~= nil then
		for k, v in pairs(grid) do
			updates[k][id] = id
			if init ~= nil then
				updates[id][k] = k
			end
		end
	end
end

local function change_grid(id, old, new)
	if old == nil then
		if grids[new] == nil then
			grids[new] = {}
		end
		grids[new][id] = id
		for i = -1, 1 do
			for j = -row_size, row_size, row_size do
				update_one_grid(id, grids[new+i+j], true)
			end
		end
	else
		grids[old][id] = nil
		if new == nil then
			for i = -1, 1 do
				for j = -row_size, row_size, row_size do
					update_one_grid(id, grids[old+i+j], true)
				end
			end
		else
			if grids[new] == nil then
				grids[new] = {}
			end
			grids[new][id] = id
			local diff = new - old
			if diff % row_size == 0 then
				for i = -1, 1 do
					update_one_grid(id, grids[new+diff+i], true)
				end
			else
				for i = -row_size, row_size, row_size do
					update_one_grid(id, grids[new+diff+i], true)
				end
			end
		end
	end
end

function CMD.init(id, info, service)
	entities[id] = info
	entities[id].id = id
	entities[id].ranges = {}
	if entities[id].type ~= "player" then
		services[id] = service
	end
	updates[id] = {}
	change_grid(id, nil, get_grid_index(info.x, info.y))
end

function CMD.move(id, x, y, dir)
	local old = get_grid_index(entities[id].x, entities[id].y)
	local new = get_grid_index(x, y)
	entities[id].x = x
	entities[id].y = y
	entities[id].dir = dir
	for i = -1, 1 do
		for j = -row_size, row_size, row_size do
			update_one_grid(id, grids[new+i+j])
		end
	end
	if old ~= new then
		change_grid(id, old, new)
	end
end

function CMD.attack(id, type, x, y)
	local r = {}
	local index = get_grid_index(entities[id].x, entities[id].y)
	for i = -1, 1 do
		for j = -row_size, row_size, row_size do
			local grid = grids[index+i+j]
			if grid ~= nil then
				for k, v in pairs(grid) do
					if k ~= id then
						table.insert(entities[k].ranges, utils.get_range_square(x, y, 1))
						if entities[k].type == type 
						and utils.in_range_square(x, y, entities[k].x, entities[k].y, 1) then
							r[k] = k
						end
					end
				end
			end
		end
	end
	return r
end

function CMD.update_hp(info)
	for k, v in pairs(info) do
		entities[k].hp = v
		local index = get_grid_index(entities[k].x, entities[k].y)
		for i = -1, 1 do
			for j = -row_size, row_size, row_size do
				update_one_grid(k, grids[index+i+j])
			end
		end
	end
end

function CMD.quit(id)
	local fd = entities[id].fd
	change_grid(id, get_grid_index(entities[id].x, entities[id].y), nil)
	updates[id] = nil
	entities[id] = nil
	return fd
end

local function push_all()
	for k, v in pairs(updates) do
		if next(v) ~= nil or next(entities[k].ranges) ~= nil then
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

	skynet.fork(function()
		while true do
			real_time = skynet.now()
			push_all()
			local diff = 10-(skynet.now()-real_time)
			if diff > 0 then
				skynet.sleep(diff)
			end
			time = time + 1
		end
	end)
end)