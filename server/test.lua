package.cpath = "./luaclib/?.so"
package.path = "./lualib/?.lua;../service/?.lua"

if _VERSION ~= "Lua 5.4" then
	error "Use lua 5.4"
end

local proto = require "proto"
local sproto = require "sproto"

local host = sproto.new(proto.s2c):host "package"
local request = host:attach(sproto.new(proto.c2s))

local fd = assert(socket.connect("127.0.0.1", 8888))

local function send_package(fd, pack)
	local package = string.pack(">s2", pack)
	assert(fd)
	print("send")
	socket.send(fd, package)
end

local function unpack_package(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s+2 then
		return nil, text
	end

	return text:sub(3,2+s), text:sub(3+s)
end

local function recv_package(last)
	local result
	result, last = unpack_package(last)
	if result then
		return result, last
	end
	local r = socket.recv(fd)
	if not r then
		return nil, last
	end
	if r == "" then
		error "Server closed"
	end
	return unpack_package(last .. r)
end

local session = 0

local function send_request(name, args)
	session = session + 1
	local str = request(name, args, session)
	send_package(fd, str)
	print("Request:", session)
end

local last = ""

local function print_request(name, args)
	print("REQUEST", name)
	if args then
		for k,v in pairs(args) do
			print(k,v)
		end
	end
end

local function print_response(session, args)
	print("RESPONSE", session)
	if args then
		for k,v in pairs(args) do
			print(k,v)
		end
	end
end

local function print_package(t, ...)
	if t == "REQUEST" then
		--print_request(...)
	else
		assert(t == "RESPONSE")
		print_response(...)
	end
end

local function dispatch_package()
	local l
	while true do
		local v
		v, last = recv_package(last)
		if not v then
			break
		end
		l = v
		print_package(host:dispatch(v))
	end
	return l
end


--send_request("handshake")
print("Welcome to the game! Please enter V to verify your account or enter C to create a new account.")
local type = io.read()
print("id:")
local id = io.read()
print("password:")
local password = io.read()
local str = type..id.."\n"..password
print(str)
send_package(fd, str)
while true do
	local r = dispatch_package()
	if r ~= nil then
		break
	end
end
send_request("getBag")
while true do
	local r = dispatch_package()
	if r ~= nil then
		break
	end
end
send_request("acqBagItem", { id = "item1", amount = 3 })
send_request("acqBagItem", { id = "weapon1", amount = 2 })
send_request("getBag")
while true do
	local r = dispatch_package()
	if r ~= nil then
		break
	end
end

while true do
	dispatch_package()
	local cmd = socket.readstdin()
	if cmd then
		if cmd == "quit" then
			send_request("quit")
		else
			send_request("hget", { key = cmd })
		end
	else
		socket.usleep(100)
	end
end
