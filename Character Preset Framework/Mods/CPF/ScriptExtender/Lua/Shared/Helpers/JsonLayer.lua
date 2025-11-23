---@class JsonLayer
--- Helper for loading and parsing JSON files
JsonLayer = {}

--- Loads a JSON file from the specified file path
---@param filePath string The file path of the JSON file to load
---@return table|nil data The parsed JSON data, or nil if the file could not be loaded or parsed
---@return string? errorMessage Error message if loading failed
function JsonLayer:Load(filePath)
    local fileContent = Ext.IO.LoadFile(filePath, "data")
    if not fileContent or fileContent == "" then
        return nil, "File not found or empty"
    end

    local success, data = pcall(Ext.Json.Parse, fileContent)
    if not success then
        return nil, "Parse error: " .. tostring(data)
    end

    return data, nil
end

return JsonLayer
