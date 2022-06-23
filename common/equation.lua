local weapon = require "weapon"
local armor = require "armor"
local attach = require "attach"

local equation = {attr = {"vit", "wil", "str", "agi"}, detail = { "hp", "mp", "atk", "def", "spd" }}

function equation.get_init_attr_val()
	return 5
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
	local total = attr["level"] * 5 + 15
	for k, v in pairs(attr) do
		if k ~= "level" then
			total = total - v
		end
	end
	return total
end

local function cal_equips(equips)
	local r = {}
	for k, v in pairs(equation.detail) do
		r[v] = 0
	end

	for k, v in pairs(equips) do
		local p
		if weapon.is_weapon(v) then
			local type = string.sub(v, 2, weapon["type_end"])
			local spec = string.sub(v, weapon["type_end"]+1, weapon["spec_end"])
			local n = string.sub("atk", 1, attach["attr_digit"])
			r[n] = r[n] + weapon["type"][type]["atk"] * weapon["spec"][spec]["level"]
			p = weapon["spec_end"] + 1
		else
			local type = string.sub(v, 2, armor["type_end"])
			local spec = string.sub(v, armor["type_end"]+1, armor["spec_end"])
			local n = string.sub("atk", 1, attach["attr_digit"])
			r[n] = r[n] + armor["type"][type]["atk"] * armor["spec"][spec]["level"]
			p = armor["spec_end"] + 1
		end

		local next
		while p < string.len(v) do
			next = p + attach["attr_digit"]
			local attr = string.sub(v, p, next-1)
			p = next
			next = p+attach["val_digit"]
			local val = string.sub(v, p, next-1)
			p = next
			r[attr] = r[attr] + tonumber(val)
		end
	end
	return r
end

function equation.cal_detail(basic_attrs, equips)
	local eq_attrs = cal_equips(equips)
	detailed_attrs = {
		hp = cal_hp(basic_attrs["vit"], basic_attrs["wil"]) + eq_attrs["hp"],
		mp = cal_mp(basic_attrs["wil"]) + eq_attrs["mp"],
		atk = basic_attrs["str"] * 10 + eq_attrs["atk"],
		def = basic_attrs["vit"] * 5 + eq_attrs["def"],
		spd = basic_attrs["agi"] * 10 + eq_attrs["spd"]
	}
	return detailed_attrs
end

function equation.cal_damage(detailed_attrs)
	
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

return equation