UserData = {}

--- Tries to access a key in the userdata table, returns the fallback if the key is not found
--- @param tbl table|userdata|nil
--- @param key string
--- @param fallback any
--- @return any
function UserData.TryGetFallback(tbl, key, fallback)
    if tbl == nil or key == nil then
        return fallback
    end
    local ok, value = pcall(function() return tbl[key] end)
    if ok and value ~= nil then
        return value
    end
    if CPFDebug then
        CPFDebug(1, "UserData.TryGetFallback: missing key '" .. tostring(key) .. "'")
    end
    return fallback
end

--- Safe single-key getter alias with options
--- @param tbl table|userdata|nil
--- @param key string
--- @param fallback any
--- @return any
function UserData.Get(tbl, key, fallback)
    return UserData.TryGetFallback(tbl, key, fallback)
end

--- Create a safe proxy that returns nil (or provided fallback) for missing keys instead of erroring
--- Access values like Safe(tbl).key or Safe(tbl):getPath({"a","b"}, default)
--- @param tbl table|userdata|nil
--- @param fallback any
--- @return table
function UserData.Safe(tbl, fallback)
    local proxy = {}
    local mt = {}

    --- @param t any
    --- @param k any
    function mt.__index(t, k)
        return UserData.TryGetFallback(tbl, k, fallback)
    end

    --- Convenience: methods on the proxy
    function proxy:get(key, def)
        return UserData.TryGetFallback(tbl, key, def)
    end

    function proxy:unwrap()
        return tbl
    end

    return setmetatable(proxy, mt)
end

return UserData
