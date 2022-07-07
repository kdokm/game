local lcontrol = require "lcontrol"
local message = require "message"
local common = require "ui_common"
local utils = require "utils"

local friend = {}
local pre = common.pre
local start_y = 12
local start_x = 5
local arrow_x = 25
local status_x = 80
local curr_offset = 1
local friends
local init = false

local function print_options()
	lcontrol.jump(0, 34)
	common.print_line()
	print(" W: previous,   S: next,   A: add/approve,   D: delete/deny\n\n")
	common.print_line()
	io.write(pre..pre.."Back (b)"..pre..pre.."Exit (Esc)")
end

local function print_friends()
	lcontrol.jump(start_x, start_y)
	io.write("ID:")
	lcontrol.jump(status_x, start_y)
	io.write("status:")

	for k, v in pairs(friends) do
		lcontrol.jump(start_x, start_y + curr_offset)
		io.write("ID:")
		lcontrol.jump(status_x, start_y + curr_offset)
		io.write("status:")
	end

	lcontrol.jump(arrow_x, start_y + curr_offset)
	io.write("<-")
	print_options()
	lcontrol.write_buffer(0)
end

function friend.update_friends(f)
	friends = f
	print_friends()
end

local function print_control(c)
	if c == "w" then
		if curr_offset > 1 then
			lcontrol.jump(arrow_x, start_y + curr_offset)
			io.write("  ")
			curr_offset = curr_offset - 1
			lcontrol.jump(arrow_x, start_y + curr_offset)
			io.write("<-")
			lcontrol.write_buffer(0)
		end
	elseif c == "s" then
		if curr_offset < utils.bag_size then
			lcontrol.jump(arrow_x, start_y + curr_offset)
			io.write("  ")
			curr_offset = curr_offset + 1
			lcontrol.jump(arrow_x, start_y + curr_offset)
			io.write("<-")
			lcontrol.write_buffer(0)
		end
	elseif c == "a" then
		
	elseif c == "d" then
		
	end
end

function friend.control(id, cmd)
	if not init then
		message.request("get_friend")
		init = true
	elseif friends ~= nil and string.len(cmd) > 0 then
		local c = string.sub(cmd, 1, 1)
		if c == "e" then
			return c
		elseif c == "b" then
			init = false
			curr_offset = 1
			lcontrol.write_buffer(1)
			return "w"
		else
			print_control(c)
		end
	end
	return "f"
end

return friend