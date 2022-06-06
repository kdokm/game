local utils = {}

function utils.genStr(num, len)
	s = tostring(num)
	while(string.len(s) < len)
	do
		s = "0"..s
	end
	return s
end

function utils.encodeDir(x, y)
	return x * 2 + y
end

function utils.decodeDir(dir)
	if dir == -2 then
		return -1, 0
	elseif dir == 2 then
		return 1, 0
	elseif dir == -1 then
		return 0, -1
	else
		return 0, 1
	end
end

function utils.dirStr(dir)
	if dir == -2 then
		return "<"
	elseif dir == 2 then
		return ">"
	elseif dir == -1 then
		return "^"
	else
		return "v"
	end
end

function utils.getInitDir()
	return 2
end

return utils