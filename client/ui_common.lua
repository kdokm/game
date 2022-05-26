local common = {
	seg = "\n\n\n\n\n",
	pre = "                              "
}

function common.print_line()
	local line = ""
	for i=1, 40 do
		line = line.."----"
	end
	print(line)
end

return common