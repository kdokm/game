local socket = require "skynet.socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"

local host = sprotoloader.load(1):host "package"
local socket_utils = {host = host, send_request = host:attach(sprotoloader.load(2))}

function socket_utils.send_package(fd, pack)
	local package = string.pack(">s2", pack)
	socket.write(fd, package)
end

return socket_utils