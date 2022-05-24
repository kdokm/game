local lsocket = require "lsocket"

local socket = {}
local fd
local message

socket.error = setmetatable({}, { __tostring = function() return "[socket error]" end } )

function socket.connect(addr, port)
	assert(fd == nil)
	fd = lsocket.connect(addr, port)
	if fd == nil then
		error(socket.error)
	end
	message = ""
end

function socket.close()
	lsocket.close(fd)
	fd = nil
	message = nil
end

function socket.read()
	while true do
		local ok, msg, n = pcall(string.unpack, ">s2", message)
		if not ok then
			local p = lsocket.recv(fd)
			if not p then
				return nil
			end
			message = message .. p
		else
			message = message:sub(n)
			return msg
		end
	end
end

function socket.write(msg)
	local pack = string.pack(">s2", msg)
	lsocket.send(fd, pack)
end

return socket
