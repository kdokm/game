local weapon = {
	type = {
		sword = {atk = 50, dist = 1, speed = 1, rate = 20},
		staff = {atk = 50, dist = 3, speed = 1, rate = 10},
		spear = {atk = 30, dist = 1, speed = 2, rate = 20}
	},
	spec = {
		starter = {level = 1, effect = "help"},
		fire = {level = 10, effect = "fire"}
	},
	type_end = 6
}

function weapon.is_weapon(id)
	local i = string.sub(id, 1, 1)
	if i == '*' then
		return true
	else
		return false
	end
end

return weapon