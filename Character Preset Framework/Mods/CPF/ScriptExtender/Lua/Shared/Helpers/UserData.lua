UserData = {}

--- Tries to access a key in the userdata table, returns the fallback if the key is not found
--- @param tbl table|userdata
--- @param key string
--- @param fallback any
--- @return any
function UserData.TryGetFallback(tbl, key, fallback)
    xpcall(function() return tbl[key] end, function()
        CPFDebug(1, "Failed to access key " .. key .. " in userdata")
        return fallback
    end)
end

return UserData
