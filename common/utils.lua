local utils = {x_max = 500, y_max = 500}

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

function utils.inRangeSquare(x1, y1, x2, y2, r)
	local d = x1 - x2
	if d > r or d < -r then
		return false
	end
	d = y1 - y2
	if d > r or d < -r then
		return false
	end
	return true
end

function utils.getRangeSquare(x, y, r)
	local range = {}
	range.upperLeft = {x=x-r, y=y-r}
	range.lowerRight = {x=x+r, y=y+r}
	return range
end

return utils