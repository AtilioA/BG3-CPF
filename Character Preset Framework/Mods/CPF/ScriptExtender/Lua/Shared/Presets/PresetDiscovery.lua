---@class PresetDiscovery
--- Service for discovering and loading character presets from mod files
PresetDiscovery = {}

-- Pattern for preset file paths
PresetDiscovery.SinglePresetPathPattern = "Mods/%s/CPF_preset.json"
PresetDiscovery.MultiPresetPathPattern = "Mods/%s/CPF_presets.json"

--- Loads a JSON file and logs appropriate errors
---@param filePath string The file path to load
---@return table|nil data The loaded data, or nil if failed
---@private
function PresetDiscovery:_LoadAndLogJSON(filePath)
    local data, err = JsonLayer:Load(filePath)

    if not data then
        if err and string.find(err, "Parse error") then
            CPFWarn(0, "Failed to parse JSON file: " .. filePath)
        else
            CPFDebug(2, "JSON file not found: " .. filePath)
        end
    end

    return data
end

--- Validates and registers a single preset
---@param preset table The preset to validate and register
---@param modName string The mod name for logging
---@param context string Additional context for logging (e.g., "index 1")
---@return boolean success Whether the preset was successfully registered
---@private
function PresetDiscovery:RegisterPreset(preset, modName, context)
    local success, regErr = PresetRegistry.Register(preset)
    if not success then
        CPFWarn(0, string.format("Failed to register preset %s from mod '%s': %s", context, modName, regErr))
        return false
    end

    CPFPrint(1, string.format("Loaded preset '%s' from mod '%s' %s", preset.Name, modName, context))
    return true
end

--- Loads and registers a single preset file
---@param modName string The mod name
---@param modDir string The mod directory
---@return integer count Number of presets loaded (0 or 1)
---@private
function PresetDiscovery:_LoadSinglePreset(modName, modDir)
    local filePath = string.format(self.SinglePresetPathPattern, modDir)
    local preset = self:_LoadAndLogJSON(filePath)

    if not preset then
        return 0
    end

    CPFPrint(1, string.format("Found CPF_preset.json in mod '%s'", modName))

    if self:RegisterPreset(preset, modName, "") then
        return 1
    end

    return 0
end

--- Loads and registers multiple presets from an array file
---@param modName string The mod name
---@param modDir string The mod directory
---@return integer count Number of presets loaded
---@private
function PresetDiscovery:_LoadMultiplePresets(modName, modDir)
    local filePath = string.format(self.MultiPresetPathPattern, modDir)
    local presets = self:_LoadAndLogJSON(filePath)

    if not presets then
        return 0
    end

    CPFPrint(1, string.format("Found CPF_presets.json in mod '%s'", modName))

    if not Table.IsArray(presets) then
        CPFWarn(0, string.format("CPF_presets.json in mod '%s' is not a valid array", modName))
        return 0
    end

    local loadedCount = 0
    for i, preset in ipairs(presets) do
        if self:RegisterPreset(preset, modName, string.format("(index %d)", i)) then
            loadedCount = loadedCount + 1
        end
    end

    return loadedCount
end

--- Tries to load and register presets for a specific mod
---@param modData table The mod data from Ext.Mod.GetMod()
---@return integer count Number of presets loaded from this mod
function PresetDiscovery:LoadPresetsForMod(modData)
    if not modData or not modData.Info or not modData.Info.Directory then
        CPFWarn(1, "Invalid mod data provided to LoadPresetsForMod")
        return 0
    end

    local modName = modData.Info.Name or modData.Info.Directory
    local modDir = modData.Info.Directory

    CPFDebug(2, string.format("Checking mod '%s' for presets...", modName))

    local loadedCount = 0
    loadedCount = loadedCount + self:_LoadSinglePreset(modName, modDir)
    loadedCount = loadedCount + self:_LoadMultiplePresets(modName, modDir)

    if loadedCount > 0 then
        CPFPrint(1, string.format("Loaded %d preset(s) from mod '%s'", loadedCount, modName))
    end

    return loadedCount
end

--- Registers a new user preset and updates the index
---@param preset Preset The preset to register
---@return boolean success
---@return string? error
function PresetDiscovery:RegisterUserPreset(preset)
    if not preset or not preset._id then
        return false, "Invalid preset"
    end

    -- Generate filename: CPF/preset_{name}_{id}.json
    -- REVIEW: Sanitize name to be safe for filenames
    local safeName = preset.Name:gsub("[^%w%-_]", "_")
    local filename = string.format("CPF/preset_%s_%s.json", safeName, preset._id)

    -- Save the preset file
    local success, err = Preset.ExportToFile(preset, filename)
    if not success then
        return false, "Failed to save preset file: " .. tostring(err)
    end

    -- Update the index
    success, err = PresetIndex.AddEntry(filename, preset._id)
    if not success then
        return false, "Failed to update preset index: " .. tostring(err)
    end

    -- Register in memory immediately
    self:RegisterPreset(preset, "User", "(User preset)")

    return true
end

--- Removes a user preset (hides it in the index)
---@param presetId string The ID of the preset to remove
---@return boolean success
---@return string? error
function PresetDiscovery:RemoveUserPreset(presetId)
    local success, err = PresetIndex.RemoveEntryByPresetId(presetId)
    if not success then
        return false, "Failed to remove preset from index: " .. tostring(err)
    end

    -- Remove from Registry
    success, err = PresetRegistry.Unregister(presetId)
    if not success then
        return false, "Failed to remove preset from registry: " .. tostring(err)
    end

    return true
end

--- Loads all presets from all mods in the load order AND user presets from registry
---@return integer totalCount Total number of presets loaded
function PresetDiscovery:LoadPresets()
    CPFPrint(0, "Starting preset discovery...")

    local totalCount = 0
    local loadOrder = Ext.Mod.GetLoadOrder()

    if not loadOrder then
        CPFWarn(0, "Failed to get mod load order")
    else
        -- Iterate through all mods in load order
        for _, modUUID in ipairs(loadOrder) do
            local modData = Ext.Mod.GetMod(modUUID)
            if modData then
                local count = self:LoadPresetsForMod(modData)
                totalCount = totalCount + count
            end
        end
    end

    -- Load User Presets from Registry
    CPFPrint(1, "Loading user presets from registry...")
    local registryEntries = PresetIndex.Load()
    for _, entry in ipairs(registryEntries) do
        if not entry.hidden then
            local preset = self:_LoadAndLogJSON(entry.filename)
            if preset then
                if self:RegisterPreset(preset, "User", "(Indexed)") then
                    totalCount = totalCount + 1
                end
            end
        end
    end

    CPFPrint(0, string.format("Preset discovery complete. Loaded %d preset(s) total.", totalCount))
    return totalCount
end

return PresetDiscovery
