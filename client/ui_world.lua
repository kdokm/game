local lcontrol = require "lcontrol"
local message = require "message"
local common = require "ui_common"
local utils = require "utils"

local world = {}
local pre = common.pre

local currX = -1
local currY = -1
local currDir = utils.getInitDir()
local currHp = -1
local currMp = -1
local entities = {}
local updates = {}
local curr_frame
local self_id

local function print_options()
	lcontrol.jump(0, 34)
	common.print_line()
	print(" W: up, S: down, A: left, D: right\n\n")
	common.print_line()
	io.write("     Character (c)"..pre..pre.."Bag (b)"..pre..pre.."Exit (Esc)")
end

local function print_upper_bar(x, y, hp, mp)
	lcontrol.jump(5, 1)
	io.write("HP: "..tostring(hp))
	currHp = hp

	lcontrol.jump(25, 1)
	io.write("MP: "..tostring(mp))
	currMp = mp

	lcontrol.jump(125, 1)
	print("position: "..tostring(x)..", "..tostring(y))
	currX = x
	currY = y
	common.print_line()
end

local function in_range(x, y)
	if x < 0 or x > 159 then
		return false
	end
	if y < 3 or y > 34 then
		return false
	end
	return true
end

local function get_related_x(x, center)
	return 80+(x-center)*10
end

local function get_related_y(y, center)
	return 16+(y-center)*2
end

local function print_ranges(args)
	local ranges = args.ranges
	local x = args.x
	local y = args.y
	for k, v in pairs(ranges) do
		local upperLeft = v.upperLeft
		local lowerRight = v.lowerRight
		upperLeft.x = math.max(0, get_related_x(upperLeft.x, x))
		upperLeft.y = math.max(3, get_related_y(upperLeft.y, y))
		lowerRight.x = math.min(159, get_related_x(lowerRight.x, x))
		lowerRight.y = math.min(34, get_related_y(lowerRight.y, y))

		for i = 0, lowerRight.y-upperLeft.y do
			lcontrol.jump(upperLeft.x, upperLeft.y+i)
			for j = 0, lowerRight.x-upperLeft.x do
				io.write(args.symbol)
			end
		end
	end
	args.time = args.time + 1
	if updates[args.time] == nil then
		args.updates = {}
		args.ranges = {}
		updates[args.time] = args
	end
end

local function print_update(args)
	print_options()
	if args.hp == 0 then
		lcontrol.jump(50, 15)
		io.write("Waiting for revive...")
	else
		local updates = args.updates
		for k, v in pairs(updates) do
			if v.id ~= self_id or entities[self_id] == nil or utils.dist(v.x, v.y, currX, currY) > 5 then
				entities[v.id] = v
			else
				entities[self_id].hp = args.hp
				entities[self_id].mp = args.mp
			end
		end
		print_upper_bar(entities[self_id].x, entities[self_id].y, entities[self_id].hp, entities[self_id].mp)
		for k, v in pairs(entities) do
			local x = get_related_x(v.x, entities[self_id].x)
			local y = get_related_y(v.y, entities[self_id].y)
			if in_range(x, y) then
				lcontrol.jump(x, y)
				io.write(utils.getDisplayID(k).."("..utils.dirStr(v.dir)..")")
				lcontrol.jump(x, y+1)
				io.write("["..tostring(v.hp).."]")
			end
		end
		if #args.ranges > 0 then
			if args.symbol == nil then
				args.symbol = "*"
			end
			print_ranges(args)
		end
		lcontrol.write_buffer()
	end
end

function world.update(args, symbol)
	args.symbol = symbol
	updates[args.time] = args
	if curr_frame == nil then
		curr_frame = args.time - 1
	end
end

function world.control(id, cmd)
	if self_id == nil then
		self_id = id
	end
	if curr_frame ~= nil then
		if updates[curr_frame] ~= nil then
			print_update(updates[curr_frame])
			updates[curr_frame] = nil
		end
		curr_frame = curr_frame + 1
	end
	if string.len(cmd) > 0 then
		local c = string.sub(cmd, 1, 1)
		local attr = {updates = {}, ranges = {}, hp=currHp, mp=currMp}
		if c == "e" then
			return true
		elseif c == "w" then
			currDir = utils.encodeDir(0, -1)
			currY = currY - 1
			message.request("move", { dir = currDir })
		elseif c == "s" then
			currDir = utils.encodeDir(0, 1)
			currY = currY + 1
			message.request("move", { dir = currDir })
		elseif c == "a" then
			currDir = utils.encodeDir(-1, 0)
			currX = currX - 1
			message.request("move", { dir = currDir })
		elseif c == "d" then
			currDir = utils.encodeDir(1, 0)
			currX = currX + 1
			message.request("move", { dir = currDir })
		elseif c == "p" then
			message.request("attack")
			local x, y = utils.decodeDir(currDir)
			table.insert(attr.ranges, utils.getRangeSquare(currX+x, currY+y, 1))
			attr.symbol = "+"
		end
		attr.x = currX
		attr.y = currY
		attr.dir = currDir
		attr.time = curr_frame
		entities[self_id] = attr
		print_update(attr)
	end
	return false
end

return world