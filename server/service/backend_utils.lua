local utils = require "utils"
local backend_utils = {pos_digit = 3, num_zones_x = 2, num_zones_y = 2, init_zones = {1, 2}}
local size_x = utils.x_max // backend_utils.num_zones_x
local size_y = utils.y_max // backend_utils.num_zones_y

local function decodeZone(zone_id)
	return zone_id % backend_utils.num_zones_x, zone_id // backend_utils.num_zones_x
end

function backend_utils.initPos(zone_id, mode)
	local zone_x, zone_y = decodeZone(zone_id)
	local x_min = zone_x * size_x
	local y_min = zone_y * size_y

	if mode == "center" then
		return x_min + size_x // 2, y_min + size_y // 2
	else
		return x_min + math.ceil(math.random() * size_x),
		           y_min + math.ceil(math.random() * size_y)
	end
end

function backend_utils.getZoneID(x, y)
	return x // size_x + y // size_y * backend_utils.num_zones_x
end

return backend_utils