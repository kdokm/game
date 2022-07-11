local utils = {bag_size = 20, x_max = 100, y_max = 100, 
	num_zones_x = 2, num_zones_y = 2, init_zones = {1, 2}, 
	attr = {"vit", "wil", "str", "agi"}, detail = { "hp", "mp", "atk", "def", "spd" }}

local size_x = utils.x_max // utils.num_zones_x
local size_y = utils.y_max // utils.num_zones_y
local monsters = {bat = "bat", wolf = "wolf"}
local monsters_in_zones = {{}, {bat=5}, {bat=5}, {wolf=3}}

function utils.gen_str(num, len)
	s = tostring(math.ceil(num))
	while(string.len(s) < len)
	do
		s = "0"..s
	end
	return s
end

function utils.sum(data)
	local s = 0
	for k, v in pairs(data) do
		s = s + v
	end
	return s
end

function utils.encode_dir(x, y)
	return x * 2 + y
end

function utils.decode_dir(dir)
	if dir == -2 then
		return -1, 0
	elseif dir == 2 then
		return 1, 0
	elseif dir == -1 then
		return 0, -1
	else
		return 0, 1
	end
end

function utils.dir_str(dir)
	if dir == -2 then
		return "<"
	elseif dir == 2 then
		return ">"
	elseif dir == -1 then
		return "^"
	else
		return "v"
	end
end

function utils.get_init_dir()
	return 2
end

function utils.in_range_square(x1, y1, x2, y2, r)
	local d = x1 - x2
	if d > r or d < -r then
		return false
	end
	d = y1 - y2
	if d > r or d < -r then
		return false
	end
	return true
end

function utils.get_range_square(x, y, r)
	local range = {}
	range.upper_left = {x=x-r, y=y-r}
	range.lower_right = {x=x+r, y=y+r}
	return range
end

local function decode_zone(zone_id)
	return zone_id % utils.num_zones_x, zone_id // utils.num_zones_x
end

function utils.init_pos(zone_id, mode)
	local zone_x, zone_y = decode_zone(zone_id)
	local x_min = zone_x * size_x
	local y_min = zone_y * size_y

	if mode == "center" then
		return x_min + size_x // 2, y_min + size_y // 2
	else
		return x_min + math.ceil(math.random() * size_x),
		           y_min + math.ceil(math.random() * size_y)
	end
end

function utils.get_zone_id(x, y)
	return x // size_x + y // size_y * utils.num_zones_x
end

function utils.dist(x1, y1, x2, y2)
	return math.abs(x1-x2) + math.abs(y1-y2)
end

function utils.get_monsters(zone_id)
	return monsters_in_zones[zone_id+1] 
end

function utils.get_display_id(id)
	local res = string.match(id, "(%l+)%d+")
	if res ~= nil and monsters[res] ~= nil then
		return res
	else
		return id
	end
end

function utils.get_detail_from_char(c)
	if c == "h" then
		return "hp"
	elseif c == "m" then
		return "mp"
	elseif c == "a" then
		return "atk"
	elseif c == "d" then
		return "def"
	else
		return "spd"
	end
end

return utils