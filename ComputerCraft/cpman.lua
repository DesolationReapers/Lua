--[[
Core Power Management Application Network

Written by
    Spector (Drive137) -- Dustin Specht

This application is provided as is and the author(s) are in no way responsible
for any damages, data lose, or otherwise any problems that may occur with use
of this program.

This source may be shared and redistrubed if the above notice is included and
notification of modification.
--]]

-- Updated Variablables
local version = "0.400"
local paste = "3iusw9Lt" -- update PASTEBIN
local programName = "cpman"
local isDebug = true --Toggle Debug mode

-- Power Unit Tables
local powerTypes = {"eu", "rf"}
local EUPowerUnits = {}
local RFPowerUnits = {}
local possibleEUPowerUnits = { "batbox", "cesu", "mfe", "mfsu" ,"gt_aesu", "gt_idsu"}
local possibleRFPowerUnits = {"tile_thermalexpansion_cell", "capcitor_bank"}
-- Updated the rf power units (not tested) and added enderio support (not tested)
-- Below are other possible RF power units but have not been tested
-- BigReactors%-Reactor  BigReactors%-Turbine tile_blockcapcitorbank_name  powered_tile

--local thermalExpansionEnergyUnit = "cofh_thermalexpansion_energycell"
local serverEUClientCount = 0
local serverRFClientCount = 0

-- Network varibales
local wirelessModem = ""
local MASTERFREQ = 0 -- TODO set before running as client server
local clients = {}
local clientID = os.getComputerID()

------------------------------- Utility function Block
-- a helper function to check if a value is contained in a certian table.
-- This really helps keep teh complexity down in some of the heavly used functions
-- since we do not have to this in there multiple times it just made sense to pull
-- it out into some other function because it is going to be used a lot.
local function inTable(tbl, item)
    for key, value in pairs(tbl) do
        if value == item then return true end
    end
end

local isAdvanced = function() return term.isColor() end
------------------------------- Update Program Block
-- This whole block ensures we have the dynamic updater which was written by
-- Soulflare3 (Soulflare3) and Drive137 (Spector)
if not fs.exists("updater") then
    shell.run("pastebin get TgWeeM59 updater")
end

os.loadAPI("updater") -- dynamic os program load to ensure things are up to date

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
-- searches the connected devices for their types and updates the tables with
-- that inforation if it is something we want
local function registerPowerUnits()
    for key, value in pairs(peripheral.getNames()) do
        if inTable(possibleEUPowerUnits, peripheral.getType(value)) then
            table.insert(EUPowerUnits, peripheral.wrap(value))
            if isDebug then print("EU Power Unit Found") end
        elseif peripheral.getType(value) == possibleRFPowerUnits then
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

-- Finds the modem and sets it to the varable used to turn on rednet in the
-- basic networking block
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
-- All four get functions here are just little macro functions to help shorten
-- some of the commands and to make it easier to handle a 0 amount since we
-- don't have to check for in complacating the functions that use these little
-- helper functions(macros).
local getEUPowerCapacity = function(euUnit) return euUnit.getEUCapacity() or 0 end
local getEUPowerStored = function(euUnit) return euUnit.getEUStored() or 0 end

local getRFEnergyCapacity = function(rfUnit) return rfUnit.getMaxEnergyStored("front") or 0 end
local getRFEnergyStored = function(rfUnit) return rfUnit.getEnergyStored("front") or 0 end

-- Clients max power calculation function. Checks what power typed was requested
-- and return the max possible amount to be stored in all devices of that type
local function calculateMaxPower(powerType)
    -- if not inTable(powerTypes, powerType) then
    --     errorHandler.Error("you have a incompatable power type being requested", powerType)
    -- end

    if powerType == powerTypes[0] then
        local maxEU = 0
        for key, value in pairs(EUPowerUnits) do
            maxEU = maxEU + getEUPowerCapacity(value)
        end
        if isDebug then print("Calculated Max EU : " .. maxEU) end
        return maxEU
    elseif powerType == powerTypes[1] then
        local maxRF = 0
        for key, value in pairs(RFPowerUnits) do
            maxRF = maxRF + getRFEnergyCapacity(value)
        end
        if isDebug then print("Calculated max RF stored : " .. maxRF) end
        return maxRF
    end
end

-- Clients calculate curent stored power. Checks what power typed was wanted
-- and calculates what is currently stored in those units.
local function calculateStoredPower(powerType)
   -- if not inTable(powerTypes, powerType) then
   --     errorHandler.Error("you have a incompatable power type being requested", powerType)
   -- end

    if powerType == powerTypes[0] then
        local storedEU = 0
        for key, value in pairs(EUPowerUnits) do
            storedEU = storedEU + getEUPowerStored(value)
        end
        if isDebug then print("Calculated current stored EU : " .. storedEU) end
        return storedEU
    elseif powerType == powerTypes[1] then
        local storedRF = 0
        for key, value in pairs(RFPowerUnits) do
            storedRF = storedRF + getRFEnergyStored(value)
        end
        if isDebug then print("Calculated current stored RF : " .. storedRF) end
        return storedRF
    end
end

----------------------------- Unit Count Block
-- A count of only a certian power type is returned from this function
local function unitCount(powerType)
    local uCount = 0
    if powerType == powerTypes[0] then
        uCount = #EUPowerUnits
    elseif powerType == powerTypes[1] then
        uCount = #RFPowerUnits
    else
        errorHandler.Error("undefined power type " .. powerType)
    end
    if isDebug then print("Counted power units of type " .. powerType) end
    return uCount
end

-- Helper function to ease the count of total power devices
local function unitCount() -- overloaded to return count of all units
    return (#EUPowerUnits + #RFPowerUnits)
end

----------------------------- Basic Networking Block
-- opens rednet on the computer so it is useable
local function loadWifi()
    if registerModemUnit() then
        rednet.open(wirelessModem)  -- Change or Define this var "wirelessModem"
    else
        errorHandler.Error("No wireless modem found Please check device connections")
    end
    if isDebug then print("wifi running") end
end

-- A helper function to shorten the broadcast function name
local broadcast = function(broadcastMessage, broadcastProtocol)
    rednet.broadcast(broadcastMessage, broadcastProtocol)
end

-- This is the function used to send basic power information over rednet and it
-- actually uses the broadcast helper function that can be foudn in the basic networking block(which is where this function should also be).
local send = function(currentPower, maximumPower, protocolCurrent, protocolMax)
    broadcast(currentPower, protocolCurrent)
    broadcast(maximumPower, protocolMax)

    if isDebug then
        print("broadcast sent")
        print("Current power : " .. currentPower .. "/" .. maximumPower)
    end
end

----------------------------- Server Network Receiving Block
local isMaster = function() if MASTERFREQ == clientID then return true else return false end end

-- This function is for the master node to control the list of clients it knows
-- about. It just checks if it is already part of this network and sends the
-- message back that the client requesting to join is already part of the network
-- and if it is not part of the network it addes the clients client ID to the
-- table of active client nodes to be checked when handling the power informoration
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

-- Global Variables for server total calculations
local serverTotalStoredEU = 0
local serverTotalMaxEU = 0
local serverTotalStoredRF = 0
local serverTotalMaxRF = 0

-- This function is where the total calculation of power happens. Creating a
-- recieved list so clients don't get counted twice per update round. Checking
-- the message for what power type to adjust and doing so to the totals.
local function serverMasterPowerCalculation()
    local clientListOfEUPowerReceived = {}
    local clientListOfRFPowerReceived = {}
    local cID, cMsg, cProtocol = rednet.receive("ClientPowerStatus") -- For each client send the power data
    local clientPowerStored = 0
    local clientPowerMaxCapacity = 0
    local clientPowerType = ""

    if not inTable(clientListOfPowerReceived, cID) then
        if(isDebug) then
            assert(cMsg ~= nil)
        end

        -- block for actually incrementing the power information
        if(cMsg ~= nil) then
            clientPowerStored = cMsg["cPowerStored"]
            clientPowerMaxCapacity = cMsg["cPowerMaxCapacity"]
            clientPowerType = cMsg["cPowerType"]

            if clientPowerType:lower() == "eu" then
                serverTotalStoredEU = serverTotalStoredEU + clientPowerStored
                serverTotalMaxEU = serverTotalMaxEU + clientPowerMaxCapacity
                rednet.send(cID, "EUpowerStatisRecieved", "powerStatis")
                table.insert(clientListOfEUPowerReceived, cID)
            elseif clientPowerType:lower() == "rf" then
                serverTotalStoredRF = serverTotalStoredRF + clientPowerStored
                serverTotalMaxRF = serverTotalMaxRF + clientPowerMaxCapacity
                rednet.send(cID, "RFpowerStatisRecieved", "powerStatis")
                table.insert(clientListOfRFPowerReceived, cID)
            end
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

---------------------------- Client Network Block
-- Sends a continuous request to the master node for this client to be added
-- to the network of nodes that are calculating power. Only exits once the master
-- node has sent a message back that it has been added. So the client is ready to
-- send it's power information along to the master.
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

-- This function is for the client node to get it's current power information and
-- send it to the master. The client check what kinds of devices it has and
-- calculates the power for all power times defined, then sends a network messege
-- to the master node with that information.
local function clientSendPowerInfo()
    local EUpowerInfoConformation = false
    local EUpowerInfo = {}

    local RFpowerInfoConformation = false
    local RFpowerInfo = {}

    -- EU power type block gets power information and sends to master after math
    -- has been done locally to calc the max and current total.
    if unitCount(powerTypes[0]) > 0 then
        while not EUpowerInfoConformation do
            EUpowerInfo["cPowerMaxCapacity"] = calculateMaxPower("eu")
            EUpowerInfo["cPowerStored"] = calculateStoredPower("eu")
            EUpowerInfo["cPowerType"] = powerTypes[0]

            rednet.send(MASTERFREQ, EUpowerInfo, "ClientPowerStatus")
            local cID, cMsg, cProtocol = rednet.receive("PowerStatus")
            if cMsg == "EUpowerStatisRecieved" then EUpowerInfoConformation = true end
        end
    end

    -- RF power type block gets power information and sends to master after math
    -- has been done locally to calc the max and current total.
    if unitCount(powerTypes[1]) > 0 then
        while not RFpowerInfoConformation do
            RFpowerInfo["cPowerMaxCapacity"] = calculateMaxPower("rf")
            RFpowerInfo["cPowerStored"] = calculateStoredPower("rf")
            RFpowerInfo["cPowerType"] = powerTypes[1]

            rednet.send(MASTERFREQ, RFpowerInfo, "PowerStatus")
            local cID, cMsg, cProtocol = rednet.receive("PowerStatus")
            if cMsg == "RFpowerStatisRecieved" then RFpowerInfoConformation = true end
        end
    end

    if isDebug then
        print("Client Power Sent and recieved server side")
    end
end

-- This is the clients main function/loop that it will run in until the program
-- exits or something causes a error to be returned from this function. All it
-- does is ensure the compture is not the faster computer for some reason. Then
-- updates the device tables with the already attached devices. Sends a request
-- to be added to the list of nodes on the network. Then goes into a infinite
-- loop of sending power information to the master server(node).
local function clientMain()
    if(isDebug) then
        assert(not isMaster)
    end

    if(not isMaster) then
        registerPowerUnits()
        clientJoinRequest()

        while true do
            clientSendPowerInfo()
        end
    else
        --TODO: maybe look at handling the cause that the master node got here?
        -- Something was not master then became master
        -- should probably restart the program to fix this
    end
end

-- This function is to handle the addition and/or the removal of
-- devices(peripherals) from the computer. This is includes things such as power
-- units and moniters. With this function being run in a async fashion it allows
-- for the calculations of power to be updated on the fly without having to
-- restart the application to get the new max power updated to the Master(server)
local function peripheralEventHandler()
    while true do
        local event, side = os.pullEvent()

        -- This is the addition block, IT looks at the peripheral and figures out
        -- what group of devices it belongs in then adds it to that groups
        -- device table so the rest of the program can have access to it easily.
        if event == "peripheral" then -- Device Added
            if ((not inTable(EUPowerUnits, side)) and (not inTable(RFPowerUnits, side))) then
                if inTable(possibleEUPowerUnits, peripheral.getType(side)) then
                    table.insert(EUPowerUnits, peripheral.wrap(side))
                    calculateMaxPower("eu") -- force recalc of Max Power
                elseif peripheral.getType(side) == possibleRFPowerUnits then
                    table.insert(RFPowerUnits, peripheral.wrap(side))
                    calculateMaxPower("rf")
                elseif peripheral.getType(side) == "moniter" then
                    --TODO add moniter table and add it here
                end
            end
            if isDebug then print("New Peripheral attached") end
        end

        -- The removal block does the reverse of the addition which is kind of
        -- obvious though we ensure we actually remove the proper device and
        -- update the table accordingly.
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

-- We do this errorHandler.Error( parrallel.waitForAny()) to have it run
-- each of the functions sent as params async to allow for something akin
-- to multi-threaded behaviour allows fewer pauses if we need to update units
--
-- This is also the entry point of the appliction. It could be a proper function
-- on it's own but it made more sense to not in cure the function call and just
-- place the structure inline.
if isMaster then
    errorHandler.Error(parallel.waitForAny(masterClientListController,peripheralEventHandler))
else
    errorHandler.Error(parallel.waitForAny(clientMain,peripheralEventHandler))
end
