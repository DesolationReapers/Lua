local function Error(message, ...) -- for Custom Error Messages
        if (... ~= nil) then
                error(string.format(message, unpack({...})))
        else
                error(string.format(message))
        end
end