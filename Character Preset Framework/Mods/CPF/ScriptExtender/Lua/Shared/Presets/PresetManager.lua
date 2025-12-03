---@class PresetManager
--- Service for managing user presets (Save, Hide, Unhide)
PresetManager = {}

--- Saves a user preset, registers it, and updates the index
---@param preset Preset The preset to save
---@return boolean success
---@return string? error
---@return string? filename
function PresetManager.SaveUserPreset(preset)
    CPFPrint(1, "PresetManager.SaveUserPreset called")

    if not preset or not preset._id then
        return false, "Invalid preset"
    end

    -- Use PresetFileManager to save the file
    if not PresetFileManager then
        return false, "PresetFileManager not loaded"
    end

    local success, err, filename = PresetFileManager:SaveUserPreset(preset)
    if not success then
        return false, err
    end

    if not filename then
        return false, "Failed to generate filename"
    end

    CPFPrint(1, "Preset file saved successfully")

    -- Update the index
    success, err = PresetIndex.AddEntry(filename, preset._id, "User")
    if not success then
        CPFWarn(0, "Failed to update preset index: " .. tostring(err))
        return false, "Failed to update preset index: " .. tostring(err)
    end

    CPFPrint(1, "Preset added to index successfully")

    -- Register in memory immediately
    local regSuccess, regErr = PresetRegistry.Register(preset)
    if not regSuccess then
        CPFWarn(0, string.format("Warning when registering user preset in registry: %s", regErr))
        return false, "Warning when registering preset in registry: " .. tostring(regErr)
    end

    -- Ensure index data is linked in registry
    PresetRegistry.UpdateIndexData(preset._id)

    CPFPrint(1, string.format("User preset '%s' registered successfully", preset.Name))
    return true, nil, filename
end

--- Hides a user preset
---@param presetId string The ID of the preset to hide
---@return boolean success
---@return string? error
function PresetManager.HidePreset(presetId)
    -- Mark as hidden in the index
    local success, err = PresetIndex.RemoveEntryByPresetId(presetId)
    if not success then
        return false, "Failed to hide preset in index: " .. tostring(err)
    end

    -- Update the preset's index data in the registry
    success = PresetRegistry.UpdateIndexData(presetId)
    if not success then
        CPFWarn(1, "Failed to update preset index data for: " .. presetId)
    end

    return true
end

--- Unhides a user preset
---@param presetId string The ID of the preset to unhide
---@return boolean success
---@return string? error
function PresetManager.UnhidePreset(presetId)
    -- Mark as unhidden in the index
    local success, err = PresetIndex.SetHidden(presetId, false)
    if not success then
        return false, "Failed to unhide preset in index: " .. tostring(err)
    end

    -- Update the preset's index data in the registry
    success = PresetRegistry.UpdateIndexData(presetId)
    if not success then
        CPFWarn(1, "Failed to update preset index data for: " .. presetId)
    end

    return true
end

return PresetManager
