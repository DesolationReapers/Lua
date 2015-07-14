--[[
	Core Power Management Application Network
--]]

-- Updated Variablables
local version = "0.301"
local paste = "3iusw9Lt"
local programName = "cpman"
local isDebug = false --Toggle Debug mode

-- Power Unit Tables
local EUPowerUnits = {}
local RFPowerUnits = {}
local possibleEUPowerUnits = { "batbox", "cesu", "mfe", "mfsu" ,"gt_aesu", "gt_idsu"}
local thermalExpansionEnergyUnit = "cofh_thermalexpansion_energycell"

-- Network varibales
local wirelessModem = ""
local MASTERFREQ = 0 -- TODO set before running as client server
local clients = {}
local clientID = os.getComputerID()

------------------------------- Utility function Block
local function inTable(tbl, item)
	for key, value in pairs(tbl) do
		if value == item then return true end
	end
end

local isAdvanced = function() return term.isColor() end
------------------------------- Update Program Block
if not fs.exists("updater") then
	shell.run("pastebin get TgWeeM59 updater")
end

os.loadAPI("updater")

if not fs.exists("errorHandler") then
	updater.forceUpdate("1Ge3dgDP","errorHandler")
end

os.loadAPI("errorHandler")

local function update()
	if (updater.update(version,paste,programName)) then
		shell.run("reboot")
	end
end
------------------------------ Device Registration Block

local function registerPowerUnits()
	for key, value in pairs(peripheral.getNames()) do
		if inTable(possibleEUPowerUnits, peripheral.getType(value)) then
			table.insert(EUPowerUnits, peripheral.wrap(value))
			if isDebug then print("EU Power Unit Found") end
        elseif peripheral.getType(value) == thermalExpansionEnergyUnit then
			table.insert(RFPowerUnits, peripheral.wrap(value))
			if isDebug then print("RF Power Unit Found") end
		else
			if isDebug then print("Unknown Power Unit") end
		end
	end
	if isDebug then print("Power Units registered") end
end
-- referenced from http://pastebin.com/raw.php?i=Jiy8jrBK

local function registerMonitorUnits() -- Save all MonitorUnits to a table of thier own
end

local function registerModemUnit()
	for key, value in pairs(peripheral.getNames()) do
		if peripheral.getType(value) == "modem" and peripheral.call(value, "isWireless") then
			wirelessModem = value
			return true
		end
	end
	if isDebug then print("Modem Unit Registered") end
end
------------------------------- Power Calculation Block

local getEUPowerCapacity = function(euUnit) return euUnit.getEUCapacity() or 0 end
local getEUPowerStored = function(euUnit) return euUnit.getEUStored() or 0 end

local getRFEnergyCapacity = function(rfUnit) return rfUnit.getMaxEnergyStored("front") or 0 end
local getRFEnergyStored = function(rfUnit) return rfUnit.getEnergyStored("front") or 0 end

local function calculateMaxPower(powerType)
	powerType = string.lower(powerType)
	if not powerType == "eu" and not powerType == "rf" then
		errorHandler.Error("you have a incompatable power type being requested", powerType)
	end

	if powerType == "eu" then
		local maxEU = 0
		for key, value in pairs(EUPowerUnits) do
			maxEU = maxEU + (getEUPowerCapacity(value) or 0)
		end
		if isDebug then print("Calculated Max EU : " .. maxEU) end
		return maxEU
	elseif powerType == "rf" then
		local maxRF = 0
		for key, value in pairs(RFPowerUnits) do
			maxRF = maxRF + (getRFEnergyCapacity(value) or 0)
		end
		if isDebug then print("Calculated max RF stored : " .. maxRF) end
		return maxRF
	end
end

local function calculateStoredPower(powerType)
	powerType = string.lower(powerType)
	if not powerType == "eu" and not powerType == "rf" then
		errorHandler.Error("you have a incompatable power type being requested", powerType)
	end

	if powerType == "eu" then
		local storedEU = 0
		for key, value in pairs(EUPowerUnits) do
			storedEU = storedEU + (getEUPowerStored(value) or 0)
		end
		if isDebug then print("Calculated current stored EU : " .. storedEU) end
		return storedEU
	elseif powerType == "rf" then
		local storedRF = 0
		for key, value in pairs(RFPowerUnits) do
			storedRF = storedRF + (getRFEnergyStored(value) or 0)
		end
		if isDebug then print("Calculated current stored RF : " .. storedRF) end
		return storedRF
	end
end

----------------------------- Unit Count Block

local function unitCount(powerType) -- return the count of a specific power type
	local uCount = 0
	powerType = string.lower(powerType)
	if powerType == "eu" then
		uCount = #EUPowerUnits
	elseif powerType == "rf" then
		uCount = #RFPowerUnits
	else
		errorHandler.Error("undefined power type " .. powerType)
	end
	if isDebug then print("Counted power units of type " .. powerType) end
	return uCount
end

local function unitCount() -- overloaded to return count of all units
	return (#EUPowerUnits + #RFPowerUnits)
end
----------------------------- Basic Networking Block

local function loadWifi()
	if registerModemUnit() then
		rednet.open(wirelessModem)  -- Change or Define this var "wirelessModem"
	else
		errorHandler.Error("No wireless modem found Please check device connections")
	end
	if isDebug then print("wifi running") end
end

local broadcast = function(broadcastMessage, broadcastProtocol) rednet.broadcast(broadcastMessage, broadcastProtocol) end
local send = function(currentPower, maximumPower, protocolCurrent, protocolMax) -- broadcasts over rednet the current and max power
	broadcast(currentPower, protocolCurrent)
	broadcast(maximumPower, protocolMax)

	if isDebug then
		print("broadcast sent")
		print("Current power : " .. currentPower .. "/" .. maximumPower)
	end
end
----------------------------- Server Network Receiving Block

local isMaster = function() if MASTERFREQ == clientID then return true else return false end end

--Master run to keep up with client list and data transmission
local function masterClientListController()
	if isMaster then
		while true do
		--(return values from rednet.reive) client ID, Message, [Distance], Protocol
			cID, cMsg, cProtocol = rednet.receive("ClientJoinRequest")
			if inTable(clients, cID) then -- if any other result How in the hell did that happen
				rednet.send(cID, "AlreadyJoinedClientList", "ClientAlreadyAccepted")
			else
				table.insert(clients, cID)
				if inTable(clients, cID) then
					rednet.send(cID, "Reqeust Accepted", "ClientJoinRequestAccepted")
				else
					rednet.send(cID, "Client failed to join list for unknown reason", "Error")
				end
			end
			sleep(0.01)
		end
	end
end

local function clientJoinRequest()
	if not isMaster then
		local cjrAccepted = false -- client join request accepted | used as a exit for the while
		while not cjrAccecpted do
			rednet.send(MASTERFREQ, "requestToJoinClientList", "ClientJoinRequest")
			sID, sMsg, sProtocol = rednet.receive()
			if sProtocol == "ClientJoinRequestAccepted" then cjrAccepted = true
			elseif sProtocol == "ClientAlreadyAccepted" then cjrAccepted = true end
		end
	end
	return cjrAccepted
end

-- Global Variables for server total calculations
local serverTotalStoredEU = 0
local serverTotalMaxEU = 0
local serverTotalStoredRF = 0
local serverTotalMaxRF = 0

local function serverMasterPowerCalculation()
	local clientListOfPowerReceived = {}
	local cID, cMsg, cProtocol = rednet.receive("ClientPowerStatus") -- For each client send the power data
	local clientPowerStored = 0
	local clientPowerMaxCapacity = 0
	local clientPowerType = ""

	if not inTable(clientListOfPowerReceived, cID) then
		assert(cMsg ~= nil)

		clientPowerStored = cMsg["cPowerStored"]
		clientPowerMaxCapacity = cMsg["cPowerMaxCapacity"]
		clientPowerType = cMsg["cPowerType"]
		-- add to the total for the server count
		if clientPowerType:lower() == "eu" then
			serverTotalStoredEU = serverTotalStoredEU + clientPowerStored
			serverTotalMaxEU = serverTotalMaxEU + clientPowerMaxCapacity
		elseif clientPowerType:lower() == "rf" then
			serverTotalStoredRF = serverTotalStoredRF + clientPowerStored
			serverTotalMaxRF = serverTotalMaxRF + clientPowerMaxCapacity
			--send (rfCurrentlyStored, maxRFPower, "storedRFPowerProtocol", "maxRFPowerProtocol")
		end

		if not isDebug then
			term.clear()
			term.setCursorPos(1,1)
		else
			if #EUPowerUnits > 0 then -- Stops nil | Undefined Error
				if euCurrentlyStored ~= 0 then print(euCurrentlyStored) end
			end

			if #RFPowerUnits > 0 then -- Stops nil | Undefined Error
				if rfCurrentlyStored ~= 0 then print(rfCurrentlyStored) end
			end
		end
		sleep(0.05)
	end
end

local function clientMain()
	assert(not isMaster)
	registerPowerUnits()
	-- Get initial max power
	calculateMaxPower("eu")
	calculateMaxPower("rf")

	while not clientJoinRequest() do --Force a addition for now till I decide to handle the error
	end

	while true do
		if unitCount("eu") > 0 then
			calculateStoredPower("eu")
		end
		if unitCount("rf") > 0 then
			calculateStoredPower("rf")
		end
	end

end

local function peripheralEventHandler()
	while true do
		local event, side = os.pullEvent()

		if event == "peripheral" then -- Device Added
			if ((not inTable(EUPowerUnits, side)) and (not inTable(RFPowerUnits, side))) then
				if inTable(possibleEUPowerUnits, peripheral.getType(side)) then
					table.insert(EUPowerUnits, peripheral.wrap(side))
					calculateMaxPower("eu") -- force recalc of Max Power
				elseif peripheral.getType(side) == thermalExpansionEnergyUnit then
					table.insert(RFPowerUnits, peripheral.wrap(side))
					calculateMaxPower("rf")
				elseif peripheral.getType(side) == "moniter" then
					--TODO add moniter table and add it here
				end
			end
			if isDebug then print("New Peripheral attached") end
		end

		if event == "peripheral_detach" then -- Device Removed
			if inTable(EUPowerUnits, side) then
				table.remove(EUPowerUnits, side)
				calculateMaxPower("eu")
			elseif inTable(RFPowerUnits, side) then
				table.remove(RFPowerUnits, side)
				calculateMaxPower("rf")
			end
			if isDebug then print("Peripheral detached") end
		end
	end
end

if isMaster then -- Main check for what to run to obtain and handle cpman
	errorHandler.Error(parallel.waitForAny(masterClientListController))
else
	errorHandler.Error(parallel.waitForAny(clientMain,peripheralEventHandler))
end
