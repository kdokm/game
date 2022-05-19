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

quit 7 {}

]]

proto.s2c = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

heartbeat 1 {}

ok 2 {}

]]

return proto
