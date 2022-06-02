local lcontrol = require "lcontrol"
local message = require "message"
local common = require "ui_common"
--local monster = require "monster"

local world = {}
local pre = common.pre

local currX = -1
local currY = -1
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
	if x < 0 or x > 160 then
		return false
	end
	if y < 3 or y > 34 then
		return false
	end
	return true
end

function world.print_update(args)
	--print(args.x)
	print_upper_bar(args.x, args.y, args.hp, args.mp)
	local updates = args.updates
	if updates == nil then
		return
	end
	for k, v in pairs(updates) do
		players[v.id] = v
	end
	for k, v in pairs(players) do
		local x = 80+(v.x-args.x)*10
		local y = 16+(v.y-args.y)*2
		if in_range(x, y) then
			lcontrol.jump(x, y)
			io.write(v.id.."("..tostring(v.hp)..")")
		end
	end
	print_options()
	lcontrol.write_buffer()
end

function world.control(cmd)
	for c in cmd:gmatch"." do
		if c == "e" then
			return true
		elseif c == "w" then
			message.request("move", { x = 0, y = -1 })
		elseif c == "s" then
			message.request("move", { x = 0, y = 1 })
		elseif c == "a" then
			message.request("move", { x = -1, y = 0 })
		elseif c == "d" then
			message.request("move", { x = 1, y = 0 })
		elseif c == "p" then
			message.request("attack")
		end
	end
	return false
end

return world