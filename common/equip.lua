local utils = require "utils"

local equip = {weapon = {
		type = {"sword", "staff", "spear"},
		detail = {
			sword = {name = "sword", atk = 50, dist = 1, spd = 20},
			staff = {name = "staff", atk = 50, dist = 3, spd = 10},
			spear = {name = "spear", atk = 30, dist = 1, spd = 20}
		}
	},
	armor = {
		type = {"upper", "lower", "shoes"},
		detail = {
			upper = {name = "armor_upper", def = 10, index = 2},
			lower = {name = "armor_lower", def = 5, index = 3},
			shoes = {name = "armor_shoes", def = 3, index = 4}
		}
	},
	grade = {
		w = {name = "white", coef = 1, rate = 0.35, exp = 10, lock = false},
		g = {name = "green", coef = 1.2, rate = 0.3, exp = 15, lock = false},
		b = {name = "blue", coef = 1.35, rate = 0.2, exp = 25, lock = false},
		p = {name = "purple", coef = 1.45, rate = 0.1, exp = 35, lock = true},
		o = {name = "orange", coef = 1.5, rate = 0.05, exp = 40, lock = true}
	},
	spec = {"sta", "fir"},
	spec_detail = {
		sta = {name = "starter", level = 1, weapon = "help", armor = "save"},
		fir = {name = "fire", level = 10, weapon = "fire", armor = "bounce"}
	},
	type_end = 6,
	spec_end = 9,
	val_digit = 2,
	equip_num = 4
}

function equip.is_weapon(id)
	local i = string.sub(id, 1, 1)
	if i == '*' then
		return true
	else
		return false
	end
end

function equip.is_armor(id)
	local i = string.sub(id, 1, 1)
	if i == '#' then
		return true
	else
		return false
	end
end

function equip.is_equip(id)
	return equip.is_weapon(id) or equip.is_armor(id)
end

local function rand_type(genre)
	local types = equip[genre].type
	return types[math.ceil(math.random() * #types)]
end

local function rand_spec(genre, max_level)
	local specs = equip.spec
	local amount = 1
	while amount <= #specs and equip.spec_detail[specs[amount]].level <= max_level do
		amount = amount + 1
	end
	return specs[math.ceil(math.random() * (amount-1))]
end

function equip.generate(max_level, max_amount, items)
	local amount = math.ceil(math.random() * max_amount)
	local genre
	local id
	for i = 1, amount do
		local id = ""
		if math.random() < 0.5 then
			genre = "weapon"
			id = "*"
		else
			genre = "armor"
			id = "#"
		end
		id = id..rand_type(genre)
		id = id..rand_spec(genre, max_level)
		items[id] = (items[id] or 0) + 1
	end
end

function equip.gen_grade()
	local rand = math.random()
	for k, v in pairs(equip.grade) do
		if rand < v.rate then
			return string.sub(k, 1, 1)
		else
			rand = rand - v.rate
		end
	end
	return equip.gen_grade()
end	

function equip.gen_attach()
	local res = ""
	local rand = math.ceil(math.random() * 4)
	for i=1, rand do
		local rand2 = math.ceil(math.random() * #utils.detail)
		local rand3 = math.ceil(math.random() * 20)
		res = res..string.sub(utils.detail[rand2],1,1)..utils.gen_str(rand3, equip.val_digit)
	end
	return res
end

function equip.gen_id(id, grade, attach)
	return id..grade..attach
end

function equip.get_type(id)
	return string.sub(id, 2, equip.type_end)
end

function equip.get_spec(id)
	return equip.spec_detail[string.sub(id, equip.type_end+1, equip.spec_end)].name
end

function equip.get_name(id)
	if equip.is_weapon(id) then
		return equip.get_spec(id).."_"..equip.get_type(id)
	else
		return equip.get_spec(id).."_armor_"..equip.get_type(id)
	end
end

function equip.get_info(id)
	local attach = {}
	for i = equip.spec_end+2, #id, equip.val_digit+1 do
		local attr = string.sub(id, i, i)
		local val = tonumber(string.sub(id, i+1, i+equip.val_digit))
		table.insert(attach, {attr = attr, val = val})
	end
	return {grade = string.sub(id, equip.spec_end+1, equip.spec_end+1), attach = attach}
end

return equip