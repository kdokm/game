local skynet = require "skynet"
local socket = require "skynet.socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
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

function REQUEST:getAttr()
	return { result = panel.getAttr() }
end

function REQUEST:updateAttr()
end

function REQUEST:getSkill()
end

function REQUEST:updateSkill()
end

function REQUEST:getPos()
	return { result = panel.getPos() }
end

function REQUEST:move()
	assert(string.len(self.command) == 6, "bad command")
	panel.move(self.command)
end

function REQUEST:getBag()
	skynet.error("get bag info")
	return { result = bag.get() }
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

function REQUEST:useBagItem()
	skynet.error("use", self.amount, self.id)
	if isEquip(self.id) then
		bag.useEquip(self.id)
	elseif string.find(self.id, "coin") ~= nil then
		bag.useCoin(self.id, self.amount)
	else
		bag.useItem(self.id, self.amount)
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

function REQUEST:move(x, y)
	attr.move(x, y)
	aoi.update(client_id, x, y)
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
	skynet.call(WATCHDOG, "lua", "close", client_fd)
end

local function request(name, args, response)
	local f = assert(REQUEST[name])
	local r = f(args)
	if response then
		return response(r)
	end
end

local function send_package(pack)
	local package = string.pack(">s2", pack)
	socket.write(client_fd, package)
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return host:dispatch(msg, sz)
	end,
	dispatch = function (fd, _, type, ...)
		assert(fd == client_fd)	-- You can use fd to reply message
		skynet.ignoreret()	-- session is fd, don't call skynet.ret
		skynet.trace()
		if type == "REQUEST" then
			local ok, result  = pcall(request, ...)
			if ok then
				if result then
					send_package(result)
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
	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))
	skynet.fork(function()
		while true do
			send_package(send_request "heartbeat")
			skynet.sleep(500)
		end
	end)
	client_fd = conf.fd
	client_id = conf.id
	skynet.call(gate, "lua", "forward", client_fd)
	skynet.error(client_fd)
	--equips = bag.init(client_id)
	local r = attr.init(client_id)
	send_package(send_request("push", r))
end

function CMD.disconnect()
	-- todo: do something before exit
	skynet.exit()
end

skynet.start(function()
	--redis = skynet.newservice("redis")
	skynet.dispatch("lua", function(_,_, command, ...)
		skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)