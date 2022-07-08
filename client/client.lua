package.path = package.path..";../common/?.lua"

if _VERSION ~= "Lua 5.4" then
	error "Use lua 5.4"
end

local lcontrol = require "lcontrol"
local socket = require "socket"
local message = require "message"
local common = require "ui_common"
local world = require "ui_world"
local character = require "ui_character"
local bag = require "ui_bag"
local friend = require "ui_friend"
local equip = require "equip"

local seg = common.seg
local pre = common.pre

local funcs = {
	w = world,
	c = character,
	b = bag,
	f = friend
}

local IP = ...

IP = IP or "127.0.0.1"

message.register(string.format("../common/sproto/proto"))

message.peer(IP, "8888")
message.connect()

local event = {}

message.bind({}, event)

local id
local time

function event:__error(what, err, req, session)
	print("error", what, err)
end

function event:push(args)
	funcs["w"].update(args)
end

function event:drop(args)
	funcs["w"].drop(args)
end

function event:get_attr(req, resp)
	if status == "c" then
		if resp.attr ~= nil then
			funcs["c"].update_attr(resp.attr)
		else
			print("error")
			lcontrol.write_buffer(1)
		end
	end
end

function event:set_attr(req, resp)
	if status == "c" then
		if resp.attr ~= nil then
			funcs["c"].update_attr(resp.attr)
		else
			print("error")
			lcontrol.write_buffer(1)
		end
	end
end

function event:get_bag(req, resp)
	if resp.items ~= nil then
		if status == "b" then
			funcs["b"].update_items(resp.items, resp.coin)
		end
		for i = 1, equip.equip_num do
			if resp.items[i] ~= nil then
				character.equips[i] = resp.items[i].id
			end
		end
	else
		print("error")
		lcontrol.write_buffer(1)
	end
end

function event:get_friends(req, resp)
	if resp.friends ~= nil then
		if status == "f" then
			funcs["f"].update_friends(resp.friends)
		end
	else
		print("error")
		lcontrol.write_buffer(1)
	end
end

local function login()
	lcontrol.jump(30, 12)
	io.write("Welcome to the game! Please enter V to verify your account or enter C to create a new account: ")
	local type = io.read()
	io.write(seg)
	io.write(pre..pre.."ID: ")
	id = io.read()
	print()
	io.write(pre..pre.."Password: ")
	local password = io.read()

	socket.write(type..id.."\n"..password)
	local status = socket.read()
	while not status do
		status = socket.read()
	end
	return status
end

os.execute("cls")
os.execute("title Game")
os.execute("mode con cols=160 lines=40")
status = login()
while status ~= "ok" do
	os.execute("cls")
	lcontrol.jump(0, 39)
	print(status.."! Please try again!")
	login()
end
os.execute("cls")
lcontrol.set_buffer()
status = "w"

time = lcontrol.get_time()
while true do
	funcs["w"].progress(status)
	local ret = funcs[status].control(id, lcontrol.get_pressed())
	if ret == "e" then
		message.request("quit")
		socket.close()
		break
	end
	status = ret
	message.update()
	time = lcontrol.sleep(time, 100)
end
