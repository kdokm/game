local lcontrol = require "lcontrol"
local message = require "message"
local common = require "ui_common"

local map = {}
local pre = common.pre

function map.print_init()
	print("W: up, S: down, A: left, D: right")
	common.print_line()
	lcontrol.jump(0, 38)
	common.print_line()
	print(pre.."     Character(c)"..pre.."Bag(b)"..pre.."Exit(Esc)")
end

function map.print_update(x, y, areas)
	lcontrol.jump(100, 0)
	print("current position: "..str(x)..", "..str(y))
end

function map.control(cmd)
	for c in cmd:gmatch"." do
		if c == "e" then
			return true
		elif c == "w" or c == "s" or c == "a" or c == "d" then
			--message.request("move", { dir = c })
		elif c == "p" then
			--message.requset("attack")
		end
	end
	return false
end

return map