local wirelessModem = ""

local function findModem()
	for key, value in pairs(peripheral.getNames()) do
		if peripheral.getType(value) == "modem" and peripheral.call(value, "isWireless") then
			wirelessModem = value
			return true
		end
	end
end
local function loadWifi()
	if findModem() then
		rednet.open(wirelessModem)  -- Change or Define this var "wirelessModem"
	else
		Error("No wireless modem found Please check device connections")
	end
	if isDebug then print("wifi running") end
end
