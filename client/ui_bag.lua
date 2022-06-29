local lcontrol = require "lcontrol"
local message = require "message"
local common = require "ui_common"
local utils = require "utils"
local equip = require "equip"

local bag = {}
local pre = common.pre
local equip_y = 5
local start_y = 10
local column_x = 85
local arrow_x = 25
local info_x = 40
local price_x = 95
local amount_x = 115
local choose_x = 130
local curr_offset = 1
local curr_amount = 1
local items
local coin = 0
local init = false

local function print_options()
	lcontrol.jump(0, 34)
	common.print_line()
	print(" W: previous item,   S: next item,   I: increase amount,   D: decrease amount,   Space: use/equip,   C: sell for coin,   A: auction\n\n")
	common.print_line()
	io.write(pre..pre.."Back (b)"..pre..pre.."Exit (Esc)")
end

local function print_equip_info(info)
	io.write("level: "..info.level)
	io.write("grade: "..equip.grade[info.grade].name)
	for i = 1, #info.main do
		local t = info.main[i]
		io.write(", "..string.upper(t.attr).."+"..t.val)
	for i = 1, #info.attach do
		local t = info.attach[i]
		io.write(", "..string.upper(t.attr).."+"..t.val.."%")
	end
end

local function print_items()
	lcontrol.jump(150, 2)
	io.write("coin: "..coin)
	lcontrol.jump(75, equip_y-1)
	print("current equip:\n")
	for i = 1, 2 do
		local index = i * 2 - 1
		if items[index] ~= nil then
			io.write(pre..pre..equip.get_name(items[index].id).."(")
			print_equip_info(equip.get_info(items[index].id))
			io.write(")")
		else
			io.write(pre..pre.."     empty")
		end
		lcontrol.jump(column_x, equip_y + i)
		index = index + 1
		if items[index] ~= nil then
			io.write(equip.get_name(items[index].id).."(")
			print_equip_info(equip.get_info(items[index].id))
			print(")")
		else
			print("     empty")
		end
	end
	io.write("\n")
	common.print_line()
	io.write("     name:")
	lcontrol.jump(info_x, start_y)
	io.write("description:")
	lcontrol.jump(price_x, start_y)
	io.write("unit price:")
	lcontrol.jump(amount_x, start_y)
	io.write("amount:")
	lcontrol.jump(choose_x, start_y)
	print("amount to use/trade:")
	for i = 1, utils.bag_size do
		local index = i + equip.equip_num
		if items[index] ~= nil then
			if equip.is_equip(items[index].id) then
				io.write("     "..equip.get_name(items[index].id))
				lcontrol.jump(info_x, start_y + i)
				print_equip_info(equip.get_info(items[index].id))
			else
				io.write("     "..items[index].id)
			end
			--lcontrol.jump(price_x, start_y + i)
			--io.write(get_price(items[index]))
			lcontrol.jump(amount_x, start_y + i)
			print(items[index].amount)
		else
			io.write("\n")
		end
	end

	lcontrol.jump(arrow_x, start_y + curr_offset)
	io.write("<-")
	if items[equip.equip_num+curr_offset] ~= nil then
		lcontrol.jump(choose_x, start_y + curr_offset)
		io.write(curr_amount)
	end
	print_options()
	lcontrol.write_buffer(0)
end

function bag.update_items(i, c)
	items = i
	coin = c
	curr_amount = 1
	print_items()
end

local function request(c, index)
	if c == "p" then
		message.request("use_bag_item", {id = items[index].id, amount = curr_amount})
	end
	lcontrol.write_buffer(1)
end

local function choose()
	lcontrol.jump(arrow_x, start_y + curr_offset)
	io.write("<-")
	curr_amount = 1
	if items[equip.equip_num+curr_offset] ~= nil then
		lcontrol.jump(choose_x, start_y + curr_offset)
		io.write(curr_amount.." ")
	end
	lcontrol.write_buffer(0)
end

local function print_control(c)
	if c == "w" then
		if curr_offset > 1 then
			lcontrol.jump(arrow_x, start_y + curr_offset)
			io.write("  ")
			lcontrol.jump(choose_x, start_y + curr_offset)
			io.write("     ")
			curr_offset = curr_offset - 1
			choose()
		end
	elseif c == "s" then
		if curr_offset < utils.bag_size then
			lcontrol.jump(arrow_x, start_y + curr_offset)
			io.write("  ")
			lcontrol.jump(choose_x, start_y + curr_offset)
			io.write("     ")
			curr_offset = curr_offset + 1
			choose()
		end
	else
		local index = curr_offset + equip.equip_num
		if items[index] == nil then
			return
		end
		if c == "i" then
			if items[index].amount > curr_amount then
				curr_amount = curr_amount + 1
				lcontrol.jump(choose_x, start_y + curr_offset)
				io.write(curr_amount.." ")
			end
		elseif c == "d" then
			if curr_amount > 0 then
				curr_amount  = curr_amount - 1
				lcontrol.jump(choose_x, start_y + curr_offset)
				io.write(curr_amount.." ")
			end
		else
			request(c, index)
		end
	end
end

function bag.control(id, cmd)
	if not init then
		message.request("get_bag")
		init = true
	elseif string.len(cmd) > 0 then
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
	return "b"
end

return bag