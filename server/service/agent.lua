local skynet = require "skynet"
local cluster = require "skynet.cluster"
local socket = require "socket"
local equip = require "equip"
local bag = require "bag"

local WATCHDOG
local host
local send_request
local equips = {}

local CMD = {}
local REQUEST = {}

local client_fd
local client_id
local zone_id

function REQUEST:get_attr()
	local r = cluster.call("global", ".attr", "get_attr", client_id)
	skynet.error(r.str)
	return {attr = r}
end

function REQUEST:set_attr()
	local a = cluster.call("global", ".attr", "update_attr", client_id, self.attr)
	cluster.call("zone", ".zone"..zone_id, "update_detail_attr", client_id, equips)
	return {attr = a}
end

function REQUEST:get_skill()
end

function REQUEST:update_skill()
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
	return equip.is_weapon(id) or equip.is_armor(id)
end

local function get_equip_index(id)
	if equip.is_weapon(id) then
		return 1
	else
		return equip.armor.detail[string.sub(id, 2, equip.type_end)].index
	end
end

local function update_equip()
	for i = 1, equip.equip_num do
		equips[i] = bag.grids[i]
	end
end

function REQUEST:use_bag_item()
	skynet.error("use", self.amount, self.id)
	if is_equip(self.id) then
		bag.move_item(self.id, get_equip_index(self.id))
		update_equip()
		cluster.call("zone", ".zone"..zone_id, "update_detail_attr", client_id, equips)
	else
		bag.use_item(self.id, self.amount)
	end
end

function REQUEST:move()
	local next = cluster.call("zone", ".zone"..zone_id, "move", client_id, self.dir)
	if next ~= nil then
		zone_id = next
	end
end

function REQUEST:attack()
	cluster.call("zone", ".zone"..zone_id, "attack", client_id)
end

function REQUEST:get_friends()
	local friends = cluster.call("global", ".friend", "get_friends", client_id)
	return {friends = friends}
end

function REQUEST:add_friend()
	cluster.call("global", ".friend", "add_friend", client_id, self.id)
end

function REQUEST:delete_friend()
	cluster.call("global", ".friend", "delete_friend", client_id, self.id)
end

function REQUEST:buy_item(id)
	--skynet.call("trade", "lua", "buy", id)
end

function REQUEST:up_equip(id)
end

function REQUEST:handshake()
	return { msg = "Welcome to skynet, I will send heartbeat every 5 sec." }
end

function REQUEST:quit()
	skynet.error("agent quit")
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
	update_equip()
	zone_id = cluster.call("world", ".world", "init_player", client_id, client_fd, skynet.self(), equips)
end

function CMD.disconnect()
	bag.store_update()
	cluster.call("zone", ".zone"..zone_id, "quit", client_id)
	skynet.exit()
end

function CMD.drop(level, exp, items)
	skynet.error(exp)
	local msgs = {}
	for k, v in pairs(items or {}) do
		skynet.error("acquire", v, k)
		if is_equip(k) then
			local msg = bag.acq_equip(k, v)
			if msg ~= nil then
				table.insert(msgs, msg)
			end
		else
			table.insert(msgs, bag.acq_item(k, v))
		end
	end
	socket.send_package(client_fd, socket.send_request("drop", {level = level, exp = exp, msgs = msgs}))
end

function CMD.push(res)
	socket.send_package(client_fd, socket.send_request("push", res))
end

function CMD.notice(id)
	socket.send_package(client_fd, socket.send_request("notice", {id = id}))
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)

	skynet.fork(function()
		while true do
			skynet.sleep(18000)
			bag.store_update()
		end
	end)
end)