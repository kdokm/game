local control = require "control"
local common = require "ui_common"

local map = {}

function map.print_options()
	control.jump(0, 38)
	common.print_line()
	print("Map(m)"..pre.."Character(c)"..pre.."Bag(b)"..pre.."Skills(s)"..pre.."Exit(e)")
end

return map