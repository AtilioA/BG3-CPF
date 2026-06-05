---@class PresetManager
--- Service for managing user presets (Save, Archive, Unarchive, Delete)
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

--- Archives a user preset
---@param presetId string The ID of the preset to archive
---@return boolean success
---@return string? error
function PresetManager.ArchivePreset(presetId)
    local success, err = PresetIndex.ArchiveEntryByPresetId(presetId)
    if not success then
        return false, "Failed to archive preset in index: " .. tostring(err)
    end

    -- Update the preset's index data in the registry
    success = PresetRegistry.UpdateIndexData(presetId)
    if not success then
        CPFWarn(1, "Failed to update preset index data for: " .. presetId)
    end

    return true
end

--- Unarchives a user preset
---@param presetId string The ID of the preset to unarchive
---@return boolean success
---@return string? error
function PresetManager.UnarchivePreset(presetId)
    local success, err = PresetIndex.SetArchived(presetId, false)
    if not success then
        return false, "Failed to unarchive preset in index: " .. tostring(err)
    end

    -- Update the preset's index data in the registry
    success = PresetRegistry.UpdateIndexData(presetId)
    if not success then
        CPFWarn(1, "Failed to update preset index data for: " .. presetId)
    end

    return true
end

--- Deletes a user preset by clearing its file and removing it from the index and registry
---@param presetId string The ID of the preset to delete
---@return boolean success
---@return string? error
function PresetManager.DeletePreset(presetId)
    local entry = PresetIndex.GetEntry(presetId)
    if not entry then
        return false, "Preset not found in index"
    end

    if string.lower(entry.source or "") ~= "user" or not entry.filename or entry.filename == "" then
        return false, "Only user preset files can be deleted"
    end

    local success, err = PresetFileManager:ClearUserPresetFile(entry.filename)
    if not success then
        return false, err
    end

    success, err = PresetIndex.DeleteEntryByPresetId(presetId)
    if not success then
        return false, "Failed to delete preset from index: " .. tostring(err)
    end

    PresetRegistry.Unregister(presetId)
    return true
end

return PresetManager
