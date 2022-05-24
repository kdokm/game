package.path = package.path..";../common/?.lua"

if _VERSION ~= "Lua 5.4" then
	error "Use lua 5.4"
end

local lcontrol = require "lcontrol"
local socket = require "socket"
local message = require "message"
local common = require "ui_common"
local map = require "ui_map"

local seg = common.seg
local pre = common.pre

local IP = ...

IP = IP or "127.0.0.1"

message.register(string.format("../common/sproto/proto"))

message.peer(IP, 8888)
message.connect()

local event = {}

message.bind({}, event)

function event:__error(what, err, req, session)
	print("error", what, err)
end

function event:push(args)
	print("server push", args.text)
end

local function login()
	lcontrol.jump(30, 12)
	io.write("Welcome to the game! Please enter V to verify your account or enter C to create a new account: ")
	local type = io.read()
	io.write(seg)
	io.write(pre..pre..pre.."ID: ")
	local id = io.read()
	print()
	io.write(pre..pre..pre.."Password: ")
	local password = io.read()

	socket.write(type..id.."\n"..password)
	local status = socket.read()
	while not status do
		status = socket.read()
	end
	return status
end

local function to_map()
	os.execute("cls")
	map.print_options()
	status = "m"
end

os.execute("cls")
os.execute("title Game")
os.execute("mode con cols=160 lines=40")
local status = login()
while status ~= "ok" do
	os.execute("cls")
	lcontrol.jump(0, 39)
	print(status.."! Please try again!")
	login()
end
to_map()

--message.request("getBag")
--message.request("acqBagItem", { id = "item1", amount = 3 })
--message.request("acqBagItem", { id = "weapon1", amount = 2 })
--message.request("getBag")

while true do
	message.update()
	lcontrol.sleep(100)
end
