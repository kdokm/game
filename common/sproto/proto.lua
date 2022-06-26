local sprotoparser = require "sprotoparser"

local proto = {}

proto.c2s = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

.attribute {
	level 0 : integer
	vit 1 : integer
	wil 2 : integer
	str 3 : integer
	agi 4 : integer
}

.item {
	id 0 : string
	pos 1 : integer
	amount 2 : integer
}

handshake 1 {
	response {
		msg 0  : string
	}
}

get_bag 2 {
	response {
		items 0 : *item(pos)
		coin 1 : integer
	}
}

move_bag_item 3 {
	request {
		id 0 : string
		newPos 1 : integer
	}
}

use_bag_item 4 {
	request {
		id 0 : string
		amount 1 : integer
	}
}

acqBagItem 6 {
	request {
		id 0 : string
		amount 1 : integer
	}
}

move 7 {
	request {
		dir 0 : integer
	}
}

attack 8 {}

get_attr 9 {
	response {
		attr 0 : attribute	
	}
}

set_attr 10 {
	request {
		attr 0 : attribute
	}
	response {
		attr 0 : attribute
	}
}

quit 11 {}

]]

proto.s2c = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

.update {
	id 0 : string
	x 1 : integer
	y 2 : integer
	hp 3 : integer
	dir 4 : integer
}

.point {
	x 0 : integer
	y 1 : integer
}

.range {
	upper_left 0 : point
	lower_right 1 : point
}

heartbeat 1 {}

push 2 {
	request {
		x 0 : integer
		y 1 : integer
		hp 2 : integer
		mp 3 : integer
		dir 4 : integer
		updates 5 : *update
		ranges 6 : *range
		time 7 : integer
	}
}

drop 3 {
	request {
		level 0 : integer
		exp 1 : integer
		items 2 : *string
	}
}

]]

return proto
