local utils = require "utils"
local equip = require "equip"

local equation = {}

function equation.get_init_attr_val()
	return 20
end

local function cal_hp(vit, wil)
	return vit * 50 + wil * 50
end

local function cal_mp(wil)
	return wil * 50
end

function equation.get_init_hp()
	local attr = equation.get_init_attr_val()
	return cal_hp(attr, attr)
end

function equation.get_init_mp()
	local attr = equation.get_init_attr_val()
	return cal_mp(attr)
end

function equation.cal_free_attr(attr)
	local total = attr["level"] * 5 + 75
	for k, v in pairs(attr) do
		if k ~= "level" then
			total = total - v
		end
	end
	return total
end

local function cal_equips(equips)
	local main = {}
	local attach = {}
	for k, v in pairs(utils.detail) do
		main[v] = 0
		attach[v] = 0
	end

	for k, v in pairs(equips) do
		local info = equip.get_info(v)
		for i = 1, #info.main do
			local t = info.main[i]
			main[t.attr] = main[t.attr] + t.val
		end
		for i = 1, #info.attach do
			local t = info.attach[i]
			attach[t.attr] = attach[t.attr] + t.val
		end
	end
	return main, attach
end

function equation.cal_detail(basic_attrs, equips)
	local main, attach = cal_equips(equips)
	detailed_attrs = {
		hp = math.floor(cal_hp(basic_attrs["vit"], basic_attrs["wil"]) * (1 + attach["hp"]/100) + main["hp"] + 0.5),
		mp = math.floor(cal_mp(basic_attrs["wil"]) * (1 + attach["mp"]/100) + main["mp"] + 0.5),
		atk = math.floor(basic_attrs["str"] * 10 * (1 + attach["atk"]/100) + main["atk"] + 0.5),
		def = math.floor(basic_attrs["vit"] * 5 * (1 + attach["def"]/100) + main["def"] + 0.5),
		spd = math.floor(basic_attrs["agi"] * 10 * (1 + attach["spd"]/100) + main["spd"] + 0.5)
	}
	return detailed_attrs
end

function equation.cal_damage(atk, def)
	local diff = atk.spd - def.spd
	if diff < 0 and math.random() * 200 < -diff then
		return 0
	end
	local val = atk.atk - def.def
	return math.max(val, 1)
end

function equation.cal_exp_required(level)
	return level * level * 100
end

function equation.cal_level_exp(level, exp, gain)
	local required = equation.cal_exp_required(level)
	exp = exp + gain
	while exp >= required do
		exp = exp - required
		level = level + 1
		required = equation.cal_exp_required(level)
	end
	return level, exp
end

function equation.cal_price(id)
	if equip.is_equip(id) then
		local price = 0
		local info = equip.get_info(id)
		for i = 1, #info.attach do
			price = price + info.attach[i].val
		end
		for i = 1, #equip.grade_list do
			if info.grade == equip.grade_list[i] then
				return price * info.level * i * i
			end
		end
	else
		return 0
	end
end

return equation