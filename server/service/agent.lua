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
	local items = {}
	for k, v in pairs(bag.items) do
		table.insert(items, v)
	end
	local coin
	if bag.coin ~= nil then
		coin = bag.coin
	else
		coin = 0
	end
	return { items = items, coin = coin }
end

function REQUEST:move_bag_item(id, new_pos)
	skynet.error("move", self.id, "to", self.new_pos)
	if bag.items[id] ~= nil then
		local msg = bag.move_item(id, new_pos)
		if msg ~= nil then
		end
	end
end

local function is_equip(id)
	return weapon.is_weapon(id) or armor.is_armor(id)
end

local function get_equip_index(id)
	if weapon.is_weapon(id) then
		return 1
	else
		return armor.type[string.sub(id, 2, type_end)].index
	end
end

function REQUEST:use_bag_item()
	skynet.error("use", self.amount, self.id)
	if is_equip(self.id) then
		bag.move_item(self.id, get_equip_index(self.id))
	else
		bag.use_item(self.id, self.amount)
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
	bag.init(client_id)
	zone = skynet.call("world", "lua", "init_player", client_id, client_fd)
end

function CMD.disconnect()
	-- todo: do something before exit
	skynet.exit()
end

function CMD.acq_bag_item(id, amount)
	skynet.error("acquire", amount, id)
	if is_equip(self.id) then
		bag.acq_equip(self.id, self.amount)
	else
		bag.acq_item(self.id, self.amount)
	end
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)