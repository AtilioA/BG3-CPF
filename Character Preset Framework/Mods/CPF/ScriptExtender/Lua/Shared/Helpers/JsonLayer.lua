---@class JsonLayer
--- Helper for loading and parsing JSON files
JsonLayer = {}

JsonLayer.ErrorCodes = {
    FILE_NOT_FOUND = "FILE_NOT_FOUND",
    PARSE_ERROR = "PARSE_ERROR",
}

JsonLayer.ErrorMessages = {
    [JsonLayer.ErrorCodes.FILE_NOT_FOUND] = "File not found or empty",
    [JsonLayer.ErrorCodes.PARSE_ERROR] = "Parse error",
}

---@param code string|nil
---@return string message
function JsonLayer:GetErrorMessage(code)
    return self.ErrorMessages[code] or tostring(code)
end

--- Loads a JSON file from the specified file path
---@param filePath string The file path of the JSON file to load
---@param mode string The mode to use when loading the file (default: "data")
---@return table|nil data The parsed JSON data, or nil if the file could not be loaded or parsed
---@return string? errorCode Error code if loading failed
function JsonLayer:Load(filePath, mode)
    local fileContent = Ext.IO.LoadFile(filePath, mode)
    if not fileContent or fileContent == "" then
        return nil, self.ErrorCodes.FILE_NOT_FOUND
    end

    local success, data = pcall(Ext.Json.Parse, fileContent)
    if not success then
        return nil, self.ErrorCodes.PARSE_ERROR
    end

    return data, nil
end

return JsonLayer
