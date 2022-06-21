local lcontrol = require "lcontrol"
local message = require "message"
local common = require "ui_common"
local utils = require "utils"

local world = {}
local pre = common.pre
local curr_x = -1
local curr_y = -1
local curr_dir = utils.get_init_dir()
local curr_hp
local curr_mp
local entities = {}
local updates = {}
local curr_frame
local self_id
local init = false

local function print_options()
	lcontrol.jump(0, 34)
	common.print_line()
	print(" W: up, S: down, A: left, D: right\n\n")
	common.print_line()
	io.write("     Character (c)"..pre..pre.."Bag (b)"..pre..pre.."Exit (Esc)")
end

local function print_upper_bar(x, y, hp, mp, dir)
	curr_hp = hp
	curr_mp = mp
	if curr_x == nil or utils.dist(x, y, curr_x, curr_y) > 5 then
		curr_x = x
		curr_y = y
		curr_dir = dir
	end

	lcontrol.jump(5, 1)
	io.write("HP: "..tostring(curr_hp))

	lcontrol.jump(25, 1)
	io.write("MP: "..tostring(curr_mp))

	lcontrol.jump(125, 1)
	print("position: "..tostring(curr_x)..", "..tostring(curr_y))
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
		local upper_left = v.upper_left
		local lower_right = v.lower_right
		upper_left.x = math.max(0, get_related_x(upper_left.x, x))
		upper_left.y = math.max(3, get_related_y(upper_left.y, y))
		lower_right.x = math.min(159, get_related_x(lower_right.x, x))
		lower_right.y = math.min(34, get_related_y(lower_right.y, y))

		for i = 0, lower_right.y-upper_left.y do
			lcontrol.jump(upper_left.x, upper_left.y+i)
			for j = 0, lower_right.x-upper_left.x do
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
	print_upper_bar(args.x, args.y, args.hp, args.mp, args.dir)
	if args.hp == 0 then
		lcontrol.jump(60, 15)
		io.write("Waiting for revive...")
	else
		local updates = args.updates
		for k, v in pairs(updates) do
			entities[v.id] = v
		end
		for k, v in pairs(entities) do
			if v.hp ~= 0 then
				local x = get_related_x(v.x, curr_x)
				local y = get_related_y(v.y, curr_y)
				if in_range(x, y) then
					lcontrol.jump(x, y)
					io.write(utils.get_display_id(k).."("..utils.dir_str(v.dir)..")")
					lcontrol.jump(x, y+1)
					io.write("["..tostring(v.hp).."]")
				end
			end
		end
		lcontrol.jump(80, 16)
		io.write(self_id.."("..utils.dir_str(curr_dir)..")")
		lcontrol.jump(80, 17)
		io.write("["..tostring(curr_hp).."]")

		if #args.ranges > 0 then
			if args.symbol == nil then
				args.symbol = "*"
			end
			print_ranges(args)
		end
	end
	lcontrol.write_buffer()
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
	if curr_hp ~= nil then
		local attr = {updates = {}, ranges = {}, hp=curr_hp, mp=curr_mp}
		local flag = false
		if not init then
			flag = true
			init = true
		elseif curr_hp > 0 and string.len(cmd) > 0 then
			flag = true
			local c = string.sub(cmd, 1, 1)
			if c == "c" or c == "b" or c == "e" then
				init = false
				curr_frame = nil
				return c
			elseif c == "w" then
				curr_dir = utils.encode_dir(0, -1)
				curr_y = curr_y - 1
				message.request("move", { dir = curr_dir })
			elseif c == "s" then
				curr_dir = utils.encode_dir(0, 1)
				curr_y = curr_y + 1
				message.request("move", { dir = curr_dir })
			elseif c == "a" then
				curr_dir = utils.encode_dir(-1, 0)
				curr_x = curr_x - 1
				message.request("move", { dir = curr_dir })
			elseif c == "d" then
				curr_dir = utils.encode_dir(1, 0)
				curr_x = curr_x + 1
				message.request("move", { dir = curr_dir })
			elseif c == "p" then
				message.request("attack")
				local x, y = utils.decode_dir(curr_dir)
				table.insert(attr.ranges, utils.get_range_square(curr_x+x, curr_y+y, 1))
				attr.symbol = "+"
			end
		end
		if flag then
			attr.x = curr_x
			attr.y = curr_y
			attr.dir = curr_dir
			attr.time = curr_frame
			print_update(attr)
		end
	end
	return "w"
end

return world