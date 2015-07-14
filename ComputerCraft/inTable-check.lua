local function inTable(tbl, item)
	for key, value in pairs(tbl) do
		if value == item then return true end
	end
end