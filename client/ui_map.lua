local lcontrol = require "lcontrol"
local common = require "ui_common"

local map = {}
local pre = common.pre

function map.print_options()
	lcontrol.jump(0, 38)
	common.print_line()
	print(pre..pre.."Character(c)"..pre.."Bag(b)"..pre.."Skills(s)"..pre.."Exit(e)")
end

return map