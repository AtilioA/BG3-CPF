---@class PresetFileManager
--- Manages file operations for user-created presets
PresetFileManager = {}

--- Generates a safe filename for a preset
---@param preset Preset
---@return string filename
---@private
function PresetFileManager:_GenerateFilename(preset)
    -- Sanitize name to be safe for filenames
    local safeName = preset.Name:gsub("[^%w%-_]", "_")
    return string.format("CPF/preset_%s_%s.json", safeName, preset._id)
end

--- Saves a user preset to file
---@param preset Preset The preset to save
---@return boolean success
---@return string? error
---@return string? filename The filename where the preset was saved
function PresetFileManager:SaveUserPreset(preset)
    if not preset or not preset._id then
        return false, "Invalid preset", nil
    end

    local filename = self:_GenerateFilename(preset)
    CPFPrint(1, string.format("Saving user preset to: %s", filename))

    -- Save the preset file
    local success, err = Preset.ExportToFile(preset, filename)
    if not success then
        CPFWarn(0, "Failed to save preset file: " .. tostring(err))
        return false, "Failed to save preset file: " .. tostring(err), nil
    end

    CPFPrint(1, "Preset file saved successfully")
    return true, nil, filename
end

--- Loads a user preset from file
---@param filename string The filename to load from
---@return Preset? preset
---@return string? error
function PresetFileManager:LoadUserPreset(filename)
    local preset, err = Preset.ImportFromFile(filename)
    if not preset then
        return nil, "Failed to load preset: " .. tostring(err)
    end
    return preset, nil
end

return PresetFileManager
