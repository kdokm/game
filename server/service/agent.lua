local skynet = require "skynet"
local socket = require "socket"
local weapon = require "weapon"
local armor = require "armor"
local bag = require "bag"
local attr = require "attr"

local WATCHDOG
local host
local send_request
local equips

local CMD = {}
local REQUEST = {}

local client_fd
local client_id
local zone

function REQUEST:get_attr()
	local r = attr.get_attr(client_id)
	skynet.error(r.str)
	return {attr = r}
end

function REQUEST:set_attr()
	attr.update_attr(client_id, self.attr)
	local a = attr.get_attr(client_id)
	skynet.call(zone, "lua", "update_attr", client_id, a)
	return {attr = a}
end

function REQUEST:getSkill()
end

function REQUEST:updateSkill()
end

function REQUEST:get_bag()
	skynet.error("get bag info")
	return { items = bag.items, coin = bag.coin }
end

function REQUEST:moveBagItem(id, newPos)
	skynet.error("move", self.id, "to", self.newPos)
	assert(string.find(id, "coin") == nil, "cannot move coin")
	bag.moveItem(id, newPos)
end

function REQUEST:exchangeBagItem(id1, id2)
	skynet.error("exchange", self.id1, "and", self.id2)
	assert(string.find(id1, "coin") == nil and string.find(id2, "coin") == nil, "cannot exchange coin")
	bag.exchangeItem(id1, id2)
end

local function isEquip(id)
	return weapon.isWeapon(id) or armor.isArmor(id)
end

function REQUEST:use_bag_item()
	skynet.error("use", self.amount, self.id)
	if isEquip(self.id) then
		bag.equip(self.id)
	elseif string.find(self.id, "coin") ~= nil then
		bag.lose_coin(self.id, self.amount)
	else
		bag.use_item(self.id, self.amount)
	end
end

function REQUEST:acqBagItem()
	skynet.error("acquire", self.amount, self.id)
	if isEquip(self.id) then
		bag.acqEquip(self.id, self.amount)
	elseif string.find(self.id, "coin") ~= nil then
		bag.acqCoin(self.id, self.amount)
	else
		bag.acqItem(self.id, self.amount)
	end
end

function REQUEST:move()
	local next = skynet.call(zone, "lua", "move", client_id, self.dir)
	if next ~= nil then
		zone = next
	end
end

function REQUEST:attack()
	skynet.call(zone, "lua", "attack", client_id)
end

function REQUEST:buyItem(id)
	--skynet.call("trade", "lua", "buy", id)
end

function REQUEST:upEquip(id)
end

function REQUEST:handshake()
	return { msg = "Welcome to skynet, I will send heartbeat every 5 sec." }
end

function REQUEST:quit()
	skynet.error("agent quit")
	skynet.call(zone, "lua", "quit", client_id)
	skynet.call(WATCHDOG, "lua", "close", client_fd)
end

local function request(name, args, response)
	local f = assert(REQUEST[name])
	local r = f(args)
	if response then
		return response(r)
	end
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return socket.host:dispatch(msg, sz)
	end,
	dispatch = function (fd, _, type, ...)
		assert(fd == client_fd)	-- You can use fd to reply message
		skynet.ignoreret()	-- session is fd, don't call skynet.ret
		skynet.trace()
		if type == "REQUEST" then
			local ok, result  = pcall(request, ...)
			if ok then
				if result then
					socket.send_package(client_fd, result)
				end
			else
				skynet.error(result)
			end
		else
			skynet.error("invalid message")
		end
	end
}

function CMD.start(conf)
	skynet.error("start agent")
	local gate = conf.gate
	WATCHDOG = conf.watchdog
	-- slot 1,2 set at main.lua
	skynet.fork(function()
		while true do
			socket.send_package(conf.fd, socket.send_request("heartbeat"))
			skynet.sleep(500)
		end
	end)
	client_fd = conf.fd
	client_id = conf.id
	skynet.call(gate, "lua", "forward", client_fd)
	skynet.error(client_fd)
	--equips = bag.init(client_id)
	zone = skynet.call("world", "lua", "init_player", client_id, client_fd)
end

function CMD.disconnect()
	-- todo: do something before exit
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)