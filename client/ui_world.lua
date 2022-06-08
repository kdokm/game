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
local players = {}

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

local function print_ranges(args, symbol)
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
				io.write(symbol)
			end
		end
	end
	lcontrol.write_buffer()
	lcontrol.sleep(100)
	args.ranges = {}
	world.print_update(args)
end

function world.print_update(args, symbol)
	print_upper_bar(args.x, args.y, args.hp, args.mp)
	local updates = args.updates
	for k, v in pairs(updates) do
		players[v.id] = v
	end
	for k, v in pairs(players) do
		local x = get_related_x(v.x, args.x)
		local y = get_related_y(v.y, args.y)
		if in_range(x, y) then
			lcontrol.jump(x, y)
			io.write(v.id.."("..utils.dirStr(v.dir)..")")
			lcontrol.jump(x, y+1)
			io.write("["..tostring(v.hp).."]")
		end
	end
	print_options()
	if #args.ranges > 0 then
		if symbol == nil then
			symbol = "*"
		end
		print_ranges(args, symbol)
	else
		lcontrol.write_buffer()
	end
end

function world.control(cmd)
	for c in cmd:gmatch"." do
		if c == "e" then
			return true
		elseif c == "w" then
			currDir = utils.encodeDir(0, -1)
			message.request("move", { dir = currDir })
		elseif c == "s" then
			currDir = utils.encodeDir(0, 1)
			message.request("move", { dir = currDir })
		elseif c == "a" then
			currDir = utils.encodeDir(-1, 0)
			message.request("move", { dir = currDir })
		elseif c == "d" then
			currDir = utils.encodeDir(1, 0)
			message.request("move", { dir = currDir })
		elseif c == "p" then
			message.request("attack")
			local attr = {x=currX, y=currY, hp=currHp, mp=currMp}
			attr.updates = {}
			attr.ranges = {}
			local x, y = utils.decodeDir(currDir)
			table.insert(attr.ranges, utils.getRangeSquare(currX+x, currY+y, 1))
			world.print_update(attr, "+")			
		end
	end
	return false
end

return world