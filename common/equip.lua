local equip = {weapon = {
		type = {
			sword = {atk = 50, dist = 1, spd = 20},
			staff = {atk = 50, dist = 3, spd = 10},
			spear = {atk = 30, dist = 1, spd = 20}
		},
		spec = {
			starter = {level = 1, effect = "help"},
			fire = {level = 10, effect = "fire"}
		},
		type_end = 6
	}
	armor = {
		type = {
			upper = {def = 10, index = 2},
			lower = {def = 5, index = 3},
			shoes = {def = 3, index = 4}
		},
		spec = {
			starter = {level = 1, effect = "save"},
			bounce = {level = 10, effect = "bounce"}
		},
		type_end = 6
	}
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

local function rand_type(genre)
	local types = equip[genre].type
	return types[math.ceil(math.random() * #types)]
end

local function rand_spec(genre, max_level)
	local specs = equip[genre].spec
	local amount = 0
	while amount <= #specs and specs[amount].level <= max_level do
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

return equip