local utils = {}

function utils.genStr(num, len)
	s = tostring(num)
	while(string.len(s) < len)
	do
		s = "0"..s
	end
	return s
end

return utils