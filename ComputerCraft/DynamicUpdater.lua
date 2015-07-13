args = {...}
local syntax = "Syntax: updater <arg> <paste> <program_name>"
local function Error(message, ...) -- for Custom Error Messages
	if (... ~= nil) then
		error(string.format(message, unpack({...})))
	else
		error(string.format(message))
	end
end

function forceUpdate(paste,programName)
	if not http then
		Error("HTTP API needs to be enabled for auto-updating")
	end
	term.clear()
	term.setCursorPos(1,1)
	print("Getting copy of "..programName.."...")
	http.request("http://pastebin.com/raw.php?i="..paste)
	local waiting = true
	while waiting do
		local event,url,handle = os.pullEvent()
		if event == "http_success" then
			print("I got a response!")
			waiting = false
			local responseCode = handle.getResponseCode()
			if responseCode == 302 then
				Error("I won't follow redirects, try again")
			elseif responseCode == 404 then
				Error("Server could not find the file specified")
			elseif responseCode == 200 then
				local reply = handle.readAll()
				if fs.exists(programName) then
					fs.delete(programName)
				end
				local file = fs.open(programName,"w")
				file.write(reply)
				file.close()
				print("New "..programName.." file successfully downloaded and installed")
			else
				print("I got a response, but that code wasn't handled!")
				print("The code was: "..responseCode)
			end
		elseif event == "http_failure" then
			waiting = false
			print("Requested paste id: "..paste)
			print("Composed URL: " .. url)
			Error("Cannot contact the server, double check your pastebin ID.\nThere may also be a problem with your internet connection. ")
		end
	end
end
if not http then
	Error("HTTP API needs to be enabled for auto-updating")
end
if not fs.exists("errorHandler") then
	forceUpdate("1Ge3dgDP","errorHandler")
end

function update(version,paste,programName)
	--ForceUpdate, with basic version checking and return values (if the PC needs a reboot or not)
	if not http then
		Error("HTTP API needs to be enabled for auto-updating")
	end
	term.clear()
	term.setCursorPos(1,1)
	print("Checking for updates...")
	http.request("http://pastebin.com/raw.php?i="..paste)
	local waiting = true
	while waiting do
		local event,url,handle = os.pullEvent()
		if event == "http_success" then
			print("I got a response!")
			waiting = false
			local responseCode = handle.getResponseCode()
			if responseCode == 302 then
				Error("I won't follow redirects, try again")
			elseif responseCode == 404 then
				Error("Server could not find the file specified")
			elseif responseCode == 200 then
				local reply = handle.readAll()
				local a, b, c, onlineVersion = string.find(reply, "([\"'])(.-)%1") --trash a,b,c http://www.lua.org/pil/20.3.html
				print("My Version: " .. version)
				print("Online Version: " .. onlineVersion)
				local rebootNeeded = false
				if(version~=onlineVersion) then
					if fs.exists(programName) then
						fs.delete(programName)
					end
					local file = fs.open(programName,"w")
					file.write(reply)
					file.close()
					print("New "..programName.." file successfully downloaded and installed")
					rebootNeeded = true -- reboot needed
				else
					print("No update found")
					rebootNeeded = false -- No update needed
				end
			else
				print("I got a response, but that code wasn't handled!")
				print("The code was: "..responseCode)
			end
		elseif event == "http_failure" then
			waiting = false
			print("Requested paste id: "..paste)
			print("Composed URL: " .. url)
			Error("Cannot contact the server, double check your pastebin ID. ")
		end
	end
	return rebootNeeded
end

local function parseResponse()
	local responseArgs = {"-f","--force","-h","--help","/?"}
	local argMatched = false
	for a,b in pairs(responseArgs) do
		if args[1] == responseArgs[a] then
			argMatched = true
			break
		end
	end
	if (argMatched) then
		if(args[1] == "-f" or args[1] == "--force") then
			forceUpdate(args[2],args[3])
		elseif(args[1] == "-h" or args[1] == "--help" or args[1] == "/?")then
			print("This program can be used as an automatic updater for CC programs")
			print("I also have the ability to force the updating of a program")
			print("Use flags -f or --force to forcibly update a program.")
			print(syntax)
		end
	else
		Error(syntax)
	end
end

if #args > 3 then
	print(syntax)
	Error("Too many arguments!")
elseif #args > 0 then
	print("Attempting to force update...")
	parseResponse()
elseif #args == 0 then
	print(syntax)
end