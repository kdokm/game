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

function world.print_init()
	print("\n\n")
	common.print_line()
	lcontrol.jump(0, 34)
	common.print_line()
	print(" W: up, S: down, A: left, D: right\n\n")
	common.print_line()
	print("     Character (c)"..pre..pre.."Bag (b)"..pre..pre.."Exit (Esc)")
end

local function print_update_bar(x, y, hp, mp)
	if x ~= currX or y ~= currY then
		lcontrol.jump(125, 1)
		print("position: "..tostring(x)..", "..tostring(y))
		currX = x
		currY = y
	end
	if hp ~= currHp then
		lcontrol.jump(5, 1)
		print("HP: "..tostring(hp))
		currHp = hp
	end
	if mp ~= currMp then
		lcontrol.jump(25, 1)
		print("MP: "..tostring(mp))
		currMp = mp
	end
end

function world.print_update(x, y, hp, mp, updates)
	print_update_bar(x, y, hp, mp)
	if updates == nil then
		return
	end
	for update in updates do
		lcontrol.jump(80+(update.x-x)*5, 16+update.y-y)
		--if update.id in monster then
		--	print(update.id.."("..update.hp..")")
		--else
			print(update.id)
		--end
	end
end

function world.control(cmd)
	for c in cmd:gmatch"." do
		if c == "e" then
			return true
		elseif c == "w" then
			message.request("move", { x = -1, y = 0 })
		elseif c == "s" then
			message.request("move", { x = 0, y = -1 })
		elseif c == "a" then
			message.request("move", { x = 1, y = 0 })
		elseif c == "d" then
			message.request("move", { x = 0, y = 1 })
		elseif c == "p" then
			--message.requset("attack")
		end
	end
	return false
end

return world