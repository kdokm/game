local sprotoparser = require "sprotoparser"

local proto = {}

proto.c2s = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

handshake 1 {
	response {
		msg 0  : string
	}
}

getBag 2 {
	response {
		result 0 : *string
	}
}

moveBagItem 3 {
	request {
		id 0 : string
		newPos 1 : integer
	}
}

exchangeBagItem 4 {
	request {
		id1 0 : string
		id2 1 : string
	}
}

useBagItem 5 {
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
		x 0 : integer
		y 1 : integer
	}
}

quit 8 {}

]]

proto.s2c = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

.update {
	x 0 : integer
	y 1 : integer
	hp 2 : integer
	id 3 : string
}

heartbeat 1 {}

]]

push 2 {
	response {
		x 0 : integer
		y 1 : integer
		hp 2 : integer
		mp 3 : integer
		updates 4 : *update
	}
}

return proto
