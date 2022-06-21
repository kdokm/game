local lcontrol = require "lcontrol"
local message = require "message"
local common = require "ui_common"
local equation = require "equation"

local character = {}
local pre = common.pre
local state
local start_y = 10
local detail_x = 90
local arrow_x = 70
local curr_offset = 2
local attr
local detail
local abilities
local init = false

local function print_options()
	lcontrol.jump(0, 34)
	common.print_line()
	if state == "attr" then
		print(" W: previous attribute,   S: next attribute,   A: add current attribute,   Space: confirm the change\n\n")
		common.print_line()
		io.write("     Ability (a)"..pre..pre.."Back (b)"..pre..pre.."Exit (Esc)")
	else
		print(" W: previous skill, S: next skill, A: level up current skill, Space: confirm the change\n\n")
		common.print_line()
		io.write("     Attribute (a)"..pre..pre.."Back (b)"..pre..pre.."Exit (Esc)")
	end
end

local function print_attr()
	state = "attr"
	lcontrol.jump(75, start_y)
	print("LEVEL: "..attr.level.."\n\n\n")
	for i = 1, #equation.attr do
		local a = equation.attr[i]
		local d = equation.detail[i]
		io.write(pre..pre..string.upper(a)..": "..attr[a])
		lcontrol.jump(detail_x, start_y + (i+1) * 2)
		print(string.upper(d)..": "..detail[d].."\n")
	end
	io.write(pre..pre.."free points: "..attr.free)
	lcontrol.jump(detail_x, start_y + 12)
	io.write("SPD: "..detail.spd)
	lcontrol.jump(arrow_x, start_y + 4)
	io.write("<-")
	print_options()
	lcontrol.write_buffer(0)
end

function character.update_attr(a)
	attr = a
	attr.free = equation.cal_free_attr(attr)
	detail = equation.cal_detail(a, {})
	print_attr()
end

local function print_control(c)
	if c == "w" then
		if curr_offset > 2 then
			lcontrol.jump(arrow_x, start_y + curr_offset * 2)
			io.write("  ")
			curr_offset = curr_offset - 1
			lcontrol.jump(arrow_x, start_y + curr_offset * 2)
			io.write("<-")
			lcontrol.write_buffer(0)
		end
	elseif c == "s" then
		if curr_offset < 5 then
			lcontrol.jump(arrow_x, start_y + curr_offset * 2)
			io.write("  ")
			curr_offset = curr_offset + 1
			lcontrol.jump(arrow_x, start_y + curr_offset * 2)
			io.write("<-")
			lcontrol.write_buffer(0)
		end
	end
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
			curr_offset = 2
			lcontrol.write_buffer(1)
			return "w"
		elseif c == "a" then
			if state == "attr" then
				print_skill()
			else
				print_attr()
			end
		else
			print_control(c)
		end
	end
	return "c"
end

return character