local weapon = require "weapon"
local armor = require "armor"
local attach = require "attach"

local equation = {}
local detail = { "hp", "mp", "atk", "def", "spd" }
for k, v in pairs(detail) do
	detail[k] = string.sub(v, 1, attach["attrDigit"])
end

function equation.getInitAttrVal()
	return 5
end

local function calHP(en, spr)
	return en * 50 + spr * 50
end

local function calMP(spr)
	return spr * 50
end

function equation.getInitHP()
	local attr = equation.getInitAttrVal()
	return calHP(attr, attr)
end

function equation.getInitMP()
	local attr = equation.getInitAttrVal()
	return calMP(attr)
end

function equation.calFreeAttrs(attrs)
	local total = attrs["level"] * 10
	for k, v in pairs(attrs) do
		if k ~= "level" then
			total = total - v
		end
	end
	return total
end

local function calEquips(equips)
	local r = {}
	for k, v in pairs(detail) do
		r[v] = 0
	end

	for k, v in pairs(equips) do
		local p
		if weapon.isWeapon(v) then
			local type = string.sub(v, 2, weapon["typeEnd"])
			local spec = string.sub(v, weapon["typeEnd"]+1, weapon["specEnd"])
			local n = string.sub("atk", 1, attach["attrDigit"])
			r[n] = r[n] + weapon["type"][type]["atk"] * weapon["spec"][spec]["level"]
			p = weapon["specEnd"] + 1
		else
			local type = string.sub(v, 2, armor["typeEnd"])
			local spec = string.sub(v, armor["typeEnd"]+1, armor["specEnd"])
			local n = string.sub("atk", 1, attach["attrDigit"])
			r[n] = r[n] + armor["type"][type]["atk"] * armor["spec"][spec]["level"]
			p = armor["specEnd"] + 1
		end

		local next
		while p < string.len(v) do
			next = p + attach["attrDigit"]
			local attr = string.sub(v, p, next-1)
			p = next
			next = p+attach["valDigit"]
			local val = string.sub(v, p, next-1)
			p = next
			r[attr] = r[attr] + tonumber(val)
		end
	end
	return r
end

function equation.calDetail(basic_attrs, equips)
	local eq_attrs = calEquips(equips)
	detailed_attrs = {
		hp = calHP(basic_attrs["end"], basic_attrs["spr"]) + eq_attrs["h"],
		mp = calMP(basic_attrs["spr"]) + eq_attrs["m"],
		atk = basic_attrs["str"] * 10 + eq_attrs["a"],
		def = basic_attrs["end"] * 5 + eq_attrs["d"],
		spd = basic_attrs["dex"] * 10 + eq_attrs["s"]
	}
	return detailed_attrs
end

function equation.calDamage(detailed_attrs)
	
end

return equation