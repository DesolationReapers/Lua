-- Currently implemented in CPMAN so see that for a example use

function peripheralEventHandler() -- run in a parrarel.wairForAny() so it run alongside your program
	while true do
		local event, side = os.pullEvent()

		if event == "peripheral" then -- Device Added event check

		end

		if event == "peripheral_detach" then -- Device Removed event check

		end
	end
end

-- more on os Events in computer craft http://computercraft.info/wiki/Os.pullEvent