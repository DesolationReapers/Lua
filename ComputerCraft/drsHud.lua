local version = "0.917"
local paste = "XT9LdRnZ"
local backupPaste = "LrqJZb0q"
local programName = "drsHud"
local isDebug = false
local tick = 0.05
local sleepTime = (2*tick)

print("Constants Set")
--This mod requires MoarPeripherals

print("Checking prerequisites")
local computerType = ""
if (term.isColor()) then
	computerType = "This is an advanced computer"
else
	computerType = "This is a basic computer"
end
print(computerType)
if not http then
	print("Sorry, "..programName.." requires HTTP to run!")
	return
end

print("Loading Dynamic Updater")

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
print("Prerequisites passed")
-- Hex Colors http://pastebin.com/jcYuPxrA
-- white, orange, magenta, lightBlue, yellow, lime, pink, gray, lightGray, cyan, purple, blue, brown, green, red, black
--local defHex = { 0xFFFFFF, 0xFFA500, 0xFF00FF, 0xADD8E6, 0xFFFF00, 0x00FF00, 0xFFC0CB, 0x808080, 0xD3D3D3, 0x00FFFF, 0x800080, 0x0000FF, 0xA52A2A, 0x008000, 0xFF0000, 0x000000 }

-- Make my life easier
-- Glasses cannot utilize Computercraft's Colors API, so we have to make our own.
-- Not quite as "clean" as colors.api but it's better than remembering hex
print("Loading color table")
local colors, colours =
{
	["white"] = 0xFFFFFF,
	["orange"] = 0xFFA500,
	["magenta"] = 0xFF00FF,
	["lightblue"] = 0xADD8E6,
	["yellow"] = 0xFFFF00,
	["lime"] = 0x00FF00,
	["green"] = 0x00FF00,
	["pink"] = 0xFFC0CB,
	["gray"] = 0x808080,
	["grey"] = 0x808080,
	["lightgray"] = 0xD3D3D3,
	["lightgrey"] = 0xD3D3D3,
	["cyan"] = 0x00FFFF,
	["purple"] = 0x800080,
	["blue"] = 0x0000FF,
	["brown"] = 0xA52A2A,
	["green"] = 0x008000,
	["red"] = 0xFF0000,
	["black"] = 0x000000
}
print("Color table loaded")
local function setColor(colorName)
	return colors[string.lower(colorName)]
end
local function setColour(colourName)
	return colours[string.lower(colourName)]
end
print("Color setting functions loaded")
--sleep(sleepTime)
print("Setting variables, this may take a while")
--Variables
local wirelessSide = "left"
local glassBridge = "bottom"
local radioSide = "back"
local wiredChatBox = "chatbox_0" --automate this eventually
local showFlow = true -- toggle flow display on or off (NYI)

local chatboxes = {}
--Protocols
local varMaxEUProtocol = "maxEUPowerProtocol"
local varStoredEUProtocol = "storedEUPowerProtocol"
local varMaxRFProtocol = "maxRFPowerProtocol"
local varStoredRFProtocol = "storedRFPowerProtocol"

-- Colors
local euBG = setColor("green")
local clockBG = setColor("white")
local textColor = setColor("white") --Set primary text colour. Will also be used as default for dynamic text.
local euTextColor = textColor
local euFlowTextColor = textColor
local rfFlowTextColor = textColor
local rfTextColor = textColor
local shadowColor = setColor("black")

--TextVars
local screenX = 5 --X position to start displaying hud text
local screenY = 15 --Y position to start displaying hud text

-- PowerDisplay Initializers
local euLevel = 0
local euFlow = 0
local euPct = 0
local euMax = 0 --Default max to 0, get capacities later
local euLevelStored = 0
local rfFlow = 0
local rfPct = 0
local rfMax = 0
local rfLevel = 0
local rfLevelStored = 0


local statusStored = 2500
local statusCurrent = 0
local health = 0

--Text Object initializers
local clock = ""
local clockText = ""
local euText = ""
local euFlowText = ""
local rfFlowText = ""
local rotorText = ""
local rfText = ""
local rfShadowText = ""
local clockShadowText = ""
local euShadowText = ""
local euFlowShadowText = ""
local rfFlowShadowText = ""
local rotorShadowText = "" -- currently unused

local runInput = true --for breaking out of loop, currently unused
print("Variables finished processing")
print("Wrapping required peripherals")
local glass = peripheral.wrap(glassBridge)
rednet.open(wirelessSide)
print("Required peripherals wrapped")

local function setupInteraction()
	if(isDebug) then
		print("ChatboxSetup function loaded")
	end
	-- chatbox = peripheral.wrap(wiredChatBox)
	for a,b in pairs(peripheral.getNames()) do
		if peripheral.getType(b) == "chatbox" then
			chatboxes[b] = peripheral.wrap(b)
		end
	end
end
print("User interaction setup parsed successfully")
print("Loading format string (thousand)")
--http://www.computercraft.info/forums2/index.php?/topic/8065-lua-thousand-separator/page__view__findpost__p__68427
local function format_thousand(v)
	local s = string.format("%d", math.floor(v))
	local pos = string.len(s) % 3
	if pos == 0 then
		pos = 3
	end
	return string.sub(s, 1, pos) .. string.gsub(string.sub(s, pos+1), "(...)", ".%1")
end
print("Format string loaded")

local function debugDisplay()
	glass.addText(85,2,"DEBUG MODE", textColor)

end

local function versionDisplay()
	glass.addText(150,2,"drsHud Version: ".. version, textColor)
end

local function addBox()
	if (isDebug) then
		glass.addBox(1,1,80,10,clockBG,0.2) --Clock
		glass.addBox(1,11,80,10,euBG,0.2) --PowerLevel
		debugDisplay()
		versionDisplay()
	end
end
print("Debug specific functions parsed")
print("Loading percentage caluculations")
--Adapted from http://www.plusheal.com/home/page/2/m/1833799/viewthread/858433-lua-text-thread-for-pitbull-4/post/4395397#p4395397

local function powerPercent(powerMax,powerLevel)
	local percent = 0
	if powerMax ~= nil then
		percent = powerLevel / powerMax;
	else
		percent = 0
	end
	return percent
end
print("Power Percentage parsed successfully")
local function powerPercentColor(powerPct)
	local color = textColor
	if ( powerPct <= 0.50 ) then
		color = (0xFF0030 + math.floor(powerPct*255)*512)
	else
		color = (0x10FF30 + math.floor((1-powerPct)*235)*131072)
	end
	return color
end
print("Power Percentage Color parsed successfully")
local function receive(listenProtocol)
	local senderID, message, sendProtocol = rednet.receive(listenProtocol)
	return message
end

local function receive(listenProtocol,waitTime)
	local senderID, message, sendProtocol = rednet.receive(listenProtocol,waitTime)
	return message
end
print("Receive protocols loaded")
local function loadNetworkValues()
	euMax = receive(varMaxEUProtocol,1)
	rfMax = receive(varMaxRFProtocol,1)
end
print("Parsing clock")
local function clockDisplay()
	clock = textutils.formatTime(os.time(), false)
	clockText.delete() --remove previous clock
	clockShadowText.delete() --remove shadow
	clockShadowText = glass.addText(screenX+1,screenY+1,"Time: " ..clock, shadowColor)
	clockText = glass.addText(screenX,screenY,"Time: " ..clock, textColor)
end

print("Loading custom rounding function")
local function round(val, decimal)
	if (decimal) then
		return math.floor( (val * 10^decimal) + 0.5) / (10^decimal)
	else
		return math.floor(val+0.5)
	end
end
print("Loading individual power display functions")
--[[
This is a work in progress.
I'm slowly breaking it down into better functions, a little at a time.
I'm also playing Minecraft, so I don't spend every waking moment coding... It'll come eventually
--]]
local function displayEU(currentLevel)
	euPct = powerPercent(euMax,currentLevel)
	euTextColor = powerPercentColor(euPct)
	euFlow = (currentLevel - euLevelStored) / 2
	euText.delete()
	euShadowText.delete()
	euShadowText = glass.addText(screenX+1,screenY+11,"EU: " .. format_thousand(currentLevel) .. " "..round(euPct*100,2).."%",shadowColor)
	euText = glass.addText(screenX,screenY+10,"EU: " .. format_thousand(currentLevel) .. " "..round(euPct*100,2).."%",euTextColor)
	euFlowText.delete()
	euFlowShadowText.delete()
	euFlowShadowText = glass.addText(screenX+1,screenY+21,"Change: ".. euFlow .. "/t" ,shadowColor)
	euFlowText = glass.addText(screenX,screenY+20,"Change: ".. euFlow .. "/t" ,euFlowTextColor)
end

local function displayRF(currentLevel)
	rfPct = powerPercent(rfMax,currentLevel)
	rfTextColor = powerPercentColor(rfPct)
	rfFlow = (currentLevel - rfLevelStored) / 2
	rfText.delete()
	rfShadowText.delete()
	rfShadowText = glass.addText(screenX+1,screenY+31,"RF: " .. format_thousand(currentLevel) .. " "..round(rfPct*100,2).."%",shadowColor)
	rfText = glass.addText(screenX,screenY+30,"RF: " .. format_thousand(currentLevel) .. " "..round(rfPct*100,2).."%",rfTextColor)
	rfFlowText.delete()
	rfFlowShadowText.delete()
	rfFlowShadowText = glass.addText(screenX+1,screenY+41,"Change: ".. rfFlow .. "/t" ,shadowColor)
	rfFlowText = glass.addText(screenX,screenY+40,"Change: ".. rfFlow .. "/t" ,rfFlowTextColor)
end

local function getCurrentLevel(varPowerType,varPowerProtocol)
	local returnLevel = receive(varPowerProtocol,tick) --powerlevel to be returned
	if (varPowerType == "eu") then --For each power type (TODO: Use an actual foreach loop and an array [Sorry for those of you who aren't familiar with terminology from Java, C#...])
		if (returnLevel == nil) then --If we didn't get a response in time
			returnLevel = euLevelStored --Use the value we saved
		end
	elseif (varPowerType == "rf") then
		if (returnLevel == nil) then
			returnLevel = rfLevelStored
		end
	end
	return returnLevel --We have to return something, whether new or old data
end
local function saveCurrentLevel(varPowerType,currentLevel)
	if (varPowerType == "eu") then
		euLevelStored = currentLevel
	elseif (varPowerType == "rf") then
		rfLevelStored = currentLevel
	else
		errorHandler.Error("Unknown power type specified, data will not be stored.")
	end
end

print("Parsing power display function")
local function powerDisplay(varPowerType,varPowerProtocol)
	varPowerType = string.lower(varPowerType)
	local currentLevel = getCurrentLevel(varPowerType,varPowerProtocol)
	if (varPowerType == "eu") then
		displayEU(currentLevel)
	elseif (varPowerType == "rf") then
		displayRF(currentLevel)
	else
		errorHandler.Error("Unknown power type specified, will not be displayed")
	end
	saveCurrentLevel(varPowerType,currentLevel)
end



print("Parsing turbine display")
local function turbineDisplay()

	statusCurrent = receive("turbineStatus",tick)
	if (statusCurrent == nil) then
		statusCurrent = statusStored
	end
	statusStored = statusCurrent
	health = 2500-statusCurrent
	rotorText.delete()
	rotorText = glass.addText(screenX,screenY+30,"Rotor Health: "..health.."/2500" ,textColor)
end

print("Parsing radio toggle")
local function radio(bool)
	if(bool) then
		redstone.setAnalogOutput(radioSide,1)
	else
		redstone.setAnalogOutput(radioSide,0)
	end
end
print("Parsing mass add function")
local function addAllText()
	if(isDebug) then
		print("addAllText function loaded")
	end
	clockShadowText = glass.addText(screenX+1,screenY+1,"Time: " ..clock, shadowColor)
	clockText = glass.addText(screenX,screenY,"Time: " ..clock, textColor)
	euShadowText = glass.addText(screenX+1,screenY+11,"EU: " .. format_thousand(euLevel) .. " "..round(euPct*100,2).."%",shadowColor)
	euText = glass.addText(screenX,screenY+10,"EU: " .. format_thousand(euLevel) .. " "..round(euPct*100,2).."%",euTextColor)
	euFlowShadowText = glass.addText(screenX+1,screenY+21,"Change: ".. euFlow .. "/t" ,shadowColor)
	euFlowText = glass.addText(screenX,screenY+20,"Change: ".. euFlow .. "/t" ,euFlowTextColor)
	rfShadowText = glass.addText(screenX+1,screenY+31,"RF: " .. format_thousand(rfLevel) .. " "..round(rfPct*100,2).."%",shadowColor)
	rfText = glass.addText(screenX,screenY+30,"RF: " .. format_thousand(rfLevel) .. " "..round(rfPct*100,2).."%",rfTextColor)
	rfFlowShadowText = glass.addText(screenX+1,screenY+41,"Change: ".. rfFlow .. "/t" ,shadowColor)
	rfFlowText = glass.addText(screenX,screenY+40,"Change: ".. rfFlow .. "/t" ,rfFlowTextColor)
	--rotorText = glass.addText(screenX,screenY+30,"Rotor Health: "..health.."/2500" ,textColor)
end
print("Parsing mass delete function")
local function deleteAllText()
	clockText.delete()
	clockShadowText.delete()
	euText.delete()
	euShadowText.delete()
	rfText.delete()
	rfShadowText.delete()
	euFlowText.delete()
	euFlowShadowText.delete()
	rfFlowText.delete()
	rfFlowShadowText.delete()
	--	rotorText.delete()
end
print("Mass delete function parsed")
print("Parsing PC>Player message function")
local function playerPrint(playerName,pcReply)
	for a,b in pairs(chatboxes) do
		b.tell(playerName,pcReply)
	end
end
print("Parsing permission request functions")
local function requestReboot(player)
	--return
end

local function requestShutdown(player)
	--"rebooting or no permission"
	--TODO:Make admin table
	--return
end

local function requestTermination(player)

end
print("Permission request functions successfully parsed")
--sleep(sleepTime)
print("Parsing input thread, this may take a while")
local function getInput()
	if(isDebug) then
		print("Input function loaded")
	end
	local test1 = 0
	local test2 = 0
	while true do
		if(isDebug) then
			print("Input loop entered")
		end
		local skipAll = false
		local e, side, player, msg = os.pullEvent()
		if e == "chatbox_command" then
			if(isDebug) then
				print("Chat conditional entered")
			end
			if msg == "test" then
				playerPrint(player,"It works!")
			elseif msg == "print" then
				playerPrint(player,msg)
			elseif msg == "terminate" then
				pcall(os.terminate)
			elseif msg == "shutdown" then
				term.clear()
				deleteAllText()
				playerPrint(player,"PC shutting down...")
				pcall(os.shutdown)
			elseif msg == "reboot" then
				term.clear()
				deleteAllText()
				playerPrint(player,"PC rebooting...")
				pcall(os.reboot)
			elseif msg == "update" then
				pcall(update)
			elseif msg == "help" then
				playerPrint(player,"Syntax: help <command>")
				playerPrint(player,"Or use ##commands to see all available commands")
			elseif msg == "about" then
				playerPrint(player,programName .. " " .. version)
			elseif msg == "clear" or msg == "term.clear" then
				term.clear()
			elseif msg == "play" then
				radio(true)
			elseif msg == "stop" or msg == "mute" then
				radio(false)
			elseif msg == "fixPower" or msg == "fixMaxPower" then
				loadNetworkValues()
			elseif msg == "debugOn" then
				isDebug = true
			elseif msg == "debugOff" then
				isDebug = false
			elseif msg == "commands" or msg == "commandlist" then
				playerPrint(player,"Available commands: test terminate shutdown reboot update help fixPower about clear play stop debugOn debugOff commands")
			end
			--Help messages
			if msg == "help terminate" then
				playerPrint(player,"Terminates the program")
			elseif msg == "help shutdown" then
				playerPrint(player,"Turns off the PC")
			elseif msg == "help reboot" then
				playerPrint(player,"Reboots the PC")
			elseif msg == "help update" then
				playerPrint(player,"Runs the drsHud updater")
			elseif msg == "help about" then
				playerPrint(player,"Shows program information")
			elseif msg == "help help" then
				playerPrint(player,"Really?")
			elseif msg == "help clear" then
				playerPrint(player,"Clears the terminal, otherwise useless")
			elseif msg == "help play" then
				playerPrint(player,"Starts the radio")
			elseif msg == "help stop" or msg == "help mute" then
				playerPrint(player,"Stops the radio")
				playerPrint(player,"Aliases: stop mute")
			elseif msg == "help fixPower" or msg == "help fixMaxPower" then
				playerPrint(player,"Updates the maximum amount of power for drsHud. Run this after changing the number of batteries")
				playerPrint(player,"Aliases: fixEU fixMaxEU")
			elseif msg == "help debugOn" then
				playerPrint(player,"Turns drsHud's debug mode on")
			elseif msg == "help debugOff" then
				playerPrint(player,"Turns drsHud's debug mode off")
			elseif msg == "help commands" or msg == "help commandlist" then
				playerPrint(player,"Print a list of available commands")
				playerPrint(player,"Aliases: commands commandlist")
			end
		end
		if (isDebug) then
			if test1 < 20 then
				test1 = test1 + 1
			else
				test1 = 0
				test2 = test2 + 1
				print(test2)
			end
		end
	end
	if(isDebug) then
		print("Input loop exited")
	end
end
print("Input thread parsed successfully")
print("Loading Main function")
local function Main()
	if(isDebug) then
		print("Main function loaded")
	else
		term.clear()
		term.setCursorPos(1,1)
	end
	glass.clear()
	update()
	addAllText() --Initialize everything
	addBox()
	loadNetworkValues()--get values from over the network
	setupInteraction()
	--glass.addIcon(5,42,124,0)
	while true do
		clockDisplay()
		powerDisplay("eu",varStoredEUProtocol)
		powerDisplay("rf",varStoredRFProtocol)
		--		turbineDisplay()
		--		addAllText()
		sleep(sleepTime) --Sleep for 2 ticks
		--		deleteAllText()
		--		glass.clear()
	end
end
print("Main thread parsed successfully")
print("Starting application")
errorHandler.Error(parallel.waitForAny(Main,getInput))