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

	for i = 1, #friends do
		lcontrol.jump(start_x, start_y + i)
		io.write(friends[i].id)
		lcontrol.jump(status_x, start_y + i)
		io.write(friends[i].status)
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
		lcontrol.jump(0, 36)
		io.write(" Please enter the ID of player that you want to add as friend:")
		lcontrol.write_buffer(0)
		lcontrol.jump_buf(3, 37)
		local id = io.read()
		message.request("add_friend", {id = id})
		lcontrol.write_buffer(1)
		message.request("get_friends")
	elseif c == "d" then
		message.request("delete_friend", {id = friends[curr_offset].id})
		lcontrol.write_buffer(1)
		message.request("get_friends")
	end
end

function friend.control(id, cmd)
	if not init then
		message.request("get_friends")
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