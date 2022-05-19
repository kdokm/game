local armor = {
	type = {
		upper = {def = 10},
		lower = {def = 5},
		shoe = {def = 3}
	},
	spec = {
		starter = {level = 1, effect = "save"},
		bounce = {level = 10, effect = "bounce"}
	},
	typeEnd = 2,
	specEnd = 5
}

function armor.isArmor(id)
	local i = string.sub(id, 1, 1)
	if i == # then
		return true
	else
		return false
	end
end

return armor