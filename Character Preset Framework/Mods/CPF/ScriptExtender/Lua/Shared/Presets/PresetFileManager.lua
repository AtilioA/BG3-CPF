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

--- Gets the appropriate entity for portrait extraction based on context
---@param targetEntity EntityHandle The target entity (usually player)
---@return EntityHandle|nil entity The entity to extract portrait from
---@private
function PresetFileManager:_GetEntityForPortrait(targetEntity)
    -- Case 1: Character Creation - use CC dummy
    if CCA.IsInCC() then
        local ccDummy = CCA.GetCCDummy()
        if ccDummy then
            CPFDebug(1, "Using CC dummy for portrait")
            return ccDummy
        end
    end

    -- Case 2: Mirror mode - use mirror dummy
    if targetEntity and CCA.HasDummy(targetEntity) then
        local mirrorDummy = DummyClient.GetDummyForEntity(targetEntity)
        if mirrorDummy then
            CPFDebug(1, "Using mirror dummy for portrait")
            return mirrorDummy
        end
    end

    -- Case 3: Regular gameplay - use player entity
    CPFDebug(1, "Using player entity for portrait")
    return targetEntity or _C()
end

--- Saves a preset portrait image if MCM setting is enabled
---@param preset Preset The preset to save portrait for
---@param targetEntity EntityHandle The entity to extract portrait from
---@return boolean success
---@return string? error
function PresetFileManager:SavePresetPortrait(preset, targetEntity)
    -- Check MCM setting
    if not MCM or not MCM.Get("auto_generate_portrait") then
        CPFDebug(1, "Portrait generation disabled via MCM setting")
        return true, nil
    end

    if not preset or not preset._id then
        return false, "Invalid preset"
    end

    -- Get the appropriate entity for portrait extraction
    local entity = self:_GetEntityForPortrait(targetEntity)
    if not entity then
        CPFWarn(1, "Could not find entity for portrait extraction")
        return false, "Could not find entity for portrait"
    end

    -- Check if entity has CustomIcon component
    if not entity.CustomIcon or not entity.CustomIcon.Icon then
        CPFDebug(1, "Entity does not have CustomIcon.Icon component")
        return false, "Entity missing CustomIcon.Icon"
    end

    -- Generate filename for portrait
    local filename = string.format("CPF/%s_%s_preset_portrait.webp", preset.Name, preset._id)
    CPFPrint(1, string.format("Saving preset portrait to: %s", filename))

    -- Save the portrait using Ext.IO.SaveFile
    local success, err = pcall(function()
        Ext.IO.SaveFile(filename, entity.CustomIcon.Icon)
    end)

    if not success then
        CPFWarn(0, "Failed to save preset portrait: " .. tostring(err))
        return false, "Failed to save portrait: " .. tostring(err)
    end

    CPFPrint(1, "Preset portrait saved successfully")
    return true, nil
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
