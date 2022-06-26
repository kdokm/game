local armor = {
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

function armor.is_armor(id)
	local i = string.sub(id, 1, 1)
	if i == '#' then
		return true
	else
		return false
	end
end

return armor