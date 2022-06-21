local lcontrol = require "lcontrol"
local message = require "message"
local common = require "ui_common"
local equation = require "equation"

local character = {}
local pre = common.pre
local state
local start_y = 10
local arrow_x = 70
local curr_offset = 0
local attr
local skills
local init = false

local function print_options()
	lcontrol.jump(0, 34)
	common.print_line()
	if state == "attr" then
		print(" W: previous attribute,   S: next attribute,   A: add current attribute,   Space: confirm the change\n\n")
		common.print_line()
		io.write("     Skill (s)"..pre..pre.."Back (b)"..pre..pre.."Exit (Esc)")
	else
		print(" W: previous skill, S: next skill, A: level up current skill, Space: confirm the change\n\n")
		common.print_line()
		io.write("     Attribute (a)"..pre..pre.."Back (b)"..pre..pre.."Exit (Esc)")
	end
end

local function print_attr()
	state = "attr"
	lcontrol.jump(0, start_y)
	for i = 1, #equation.attr do
		print(pre..pre..equation.attr[i]..": "..attr[equation.attr[i]])
		print()
	end
	lcontrol.jump(arrow_x, start_y)
	io.write("<-")
	print_options()
	lcontrol.write_buffer()
end

function character.update_attr(a)
	attr = a
	print_attr()
end

local function print_control(c)
end

function character.control(id, cmd)
	if state == nil then
		if attr == nil then
			if not init then
				message.request("get_attr")
				init = true
			end
		else
			print_attr()
		end
	elseif string.len(cmd) > 0 then
		local c = string.sub(cmd, 1, 1)
		if c == "e" then
			return c
		elseif c == "b" then
			state = nil
			curr_offset = 0
			return "w"
		elseif c == "s" then
			if state == "attr" then
				print_skill()
			end
		elseif c == "a" then
			if state == "skill" then
				print_attr()
			end
		else
			print_control(c)
		end
	end
	return "c"
end

return character