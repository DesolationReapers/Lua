--Fully expanded, readability improved
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

--Compressed, half size (line wise), 5 bytes smaller, if that's important to you...
if not fs.exists("updater") then shell.run("pastebin get TgWeeM59 updater") end
os.loadAPI("updater")
if not fs.exists("errorHandler") then updater.forceUpdate("1Ge3dgDP","errorHandler") end
os.loadAPI("errorHandler")
local function update()
	if (updater.update(version,paste,programName)) then shell.run("reboot") end
end