local version = "0.841" --Change as needed (must be first uncommented line of code, sorry)
local paste = "CE6UTmJ5" --Change to your pastebin
local programName = "drsHud" --Change to your program name
local isDebug = false --Toggle Debug mode

local function update()
    term.clear()
    print("Checking for updates...")
    local response = http.get("http://pastebin.com/raw.php?i="..paste)

    local reply = response.readAll()

    local a, b, c, onlineVersion = string.find(reply, "([\"'])(.-)%1") --trash a,b,c http://www.lua.org/pil/20.3.html
    print("My Version: " .. version)
    print("Online Version: " .. onlineVersion)
    if(version~=onlineVersion) then

        fs.delete(programName)
        local file = fs.open(programName,"w")
        file.write(reply)
        file.close()

        print("New "..programName.." file successfully downloaded and installed")

        if(isDebug) then
            print("Please Reboot (CTRL+R)")
        else
            shell.run("reboot")
        end
    else
        print("No update found")
    end
end