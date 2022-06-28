local lcontrol = require "lcontrol"
local message = require "message"
local common = require "ui_common"
local utils = require "utils"
local equation = require "equation"

local character = {}
local pre = common.pre
local state
local start_y = 10
local detail_x = 90
local arrow_x = 70
local curr_offset = 1
local attr
local add_points_attr = {sum = 0}
local abilities
local add_points_abilities = {sum = 0}
local init = false

local function print_options()
	lcontrol.jump(0, 34)
	common.print_line()
	if state == "attr" then
		print(" W: previous attribute,   S: next attribute,   I: increase current attribute,   D: decrease current attribute,   Space: confirm the change\n\n")
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
	lcontrol.jump(75, start_y - 2)
	print("LEVEL: "..attr.level.."\n\n\n")
	local modified_attr = {}
	for i = 1, #utils.attr do
		local a = utils.attr[i]
		modified_attr[a] = attr[a] + add_points_attr[i]
		print(pre..pre..string.upper(a)..": "..modified_attr[a].."\n")
	end
	io.write(pre..pre.."free points: "..attr.free-add_points_attr.sum)
	if add_points_attr.sum > 0 then
		io.write(" (unsaved)")
	end
	local detail = equation.cal_detail(modified_attr, {})
	for i = 1, #utils.detail do
		local d = utils.detail[i]
		lcontrol.jump(detail_x, start_y + i * 2)
		print(string.upper(d)..": "..detail[d].."\n")
	end
	lcontrol.jump(arrow_x, start_y + curr_offset * 2)
	io.write("<-")
	print_options()
	lcontrol.write_buffer(0)
end

local function zero_add_points(add_points)
	for i = 1, #add_points do
		add_points[i] = 0
	end
	add_points.sum = 0
end

function character.update_attr(a)
	attr = a
	attr.free = equation.cal_free_attr(attr)
	zero_add_points(add_points_attr)
	print_attr()
end

local function update_add_points(c, to_update, add_points)
	local flag = false
	if c == "i" then
		if to_update.free > add_points.sum then
			add_points[curr_offset] = add_points[curr_offset] + 1
			add_points.sum  = add_points.sum + 1
			flag = true
		end
	elseif c == "d" then
		if add_points[curr_offset] > 0 then
			add_points[curr_offset] = add_points[curr_offset] - 1
			add_points.sum  = add_points.sum - 1
			flag = true
		end
	elseif c == "p" then
		local a = {}
		for i = 1, #equation[state] do
			local k = equation[state][i]
			a[k] = attr[k] + add_points[i]
		end
		message.request("set_"..state, {attr = a})
		lcontrol.write_buffer(1)
	end
	return flag
end

local function print_control(c)
	if c == "w" then
		if curr_offset > 1 then
			lcontrol.jump(arrow_x, start_y + curr_offset * 2)
			io.write("  ")
			curr_offset = curr_offset - 1
			lcontrol.jump(arrow_x, start_y + curr_offset * 2)
			io.write("<-")
			lcontrol.write_buffer(0)
		end
	elseif c == "s" then
		if curr_offset < #equation[state] then
			lcontrol.jump(arrow_x, start_y + curr_offset * 2)
			io.write("  ")
			curr_offset = curr_offset + 1
			lcontrol.jump(arrow_x, start_y + curr_offset * 2)
			io.write("<-")
			lcontrol.write_buffer(0)
		end
	else
		local flag
		if state == "attr" then
			flag = update_add_points(c, attr, add_points_attr)
			if flag then
				lcontrol.write_buffer(1)
				print_attr()
			end
		else
			update_add_points(c, abilities, add_points_abilities)
			if flag then
			end
		end
	end
end

function character.control(id, cmd)
	if state == nil then
		if not init then
			message.request("get_attr")
			for i = 1, #utils.attr do
				table.insert(add_points_attr, 0)
			end
			init = true
		elseif attr ~= nil then
			print_attr()
		end
	elseif string.len(cmd) > 0 then
		local c = string.sub(cmd, 1, 1)
		if c == "e" then
			return c
		elseif c == "b" then
			state = nil
			init = false
			curr_offset = 1
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