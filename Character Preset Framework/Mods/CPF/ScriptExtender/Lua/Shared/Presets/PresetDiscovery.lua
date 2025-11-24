---@class PresetDiscovery
--- Service for discovering and loading character presets from mod files
PresetDiscovery = {}

-- Pattern for preset file paths
PresetDiscovery.SinglePresetPathPattern = "Mods/%s/CPF_preset.json"
PresetDiscovery.MultiPresetPathPattern = "Mods/%s/CPF_presets.json"

--- Loads a JSON file and logs appropriate errors
---@param filePath string The file path to load
---@param mode string The mode to load the file with
---@return table|nil data The loaded data, or nil if failed
---@private
function PresetDiscovery:_LoadAndLogJSON(filePath, mode)
    local data, err = JsonLayer:Load(filePath, mode)

    if not data then
        if err and string.find(err, "Parse error") then
            CPFWarn(0, "Failed to parse JSON file: " .. filePath)
        else
            CPFDebug(3, "JSON file not found: " .. filePath)
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

    -- Add to index (for all presets, mod or user)
    local source = (modName == "User") and "User" or modName
    local filename = "" -- Mod presets don't have user-accessible filenames
    PresetIndex.AddEntry(filename, preset._id, source)

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
    local preset = self:_LoadAndLogJSON(filePath, 'data')

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
    local presets = self:_LoadAndLogJSON(filePath, 'data')

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

    CPFDebug(3, string.format("Checking mod '%s' for presets...", modName))

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
    CPFPrint(1, "PresetDiscovery:RegisterUserPreset called")

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
        CPFWarn(0, string.format("Failed to register user preset in registry: %s", regErr))
        return false, "Failed to register preset in registry: " .. tostring(regErr)
    end

    CPFPrint(1, string.format("User preset '%s' registered successfully", preset.Name))
    return true
end

--- Removes a user preset (hides it in the index)
---@param presetId string The ID of the preset to remove
---@return boolean success
---@return string? error
function PresetDiscovery:HideUserPreset(presetId)
    -- Mark as hidden in the index
    local success, err = PresetIndex.RemoveEntryByPresetId(presetId)
    if not success then
        return false, "Failed to hide preset in index: " .. tostring(err)
    end

    -- Update the preset's index data in the registry (don't unregister)
    -- This keeps the preset loaded but marked as hidden
    success = PresetRegistry.UpdateIndexData(presetId)
    if not success then
        CPFWarn(1, "Failed to update preset index data for: " .. presetId)
    end

    return true
end

--- Loads and registers numbered user presets (preset_0.json to preset_9.json)
---@return integer count Number of presets loaded
---@private
function PresetDiscovery:_LoadNumberedUserPresets()
    CPFPrint(1, "Scanning for numbered user presets (preset_0 to preset_9)...")

    local loadedCount = 0

    -- Scan from 0 to 9
    for i = 0, 9 do
        local filename = string.format("CPF/preset_%01d.json", i)
        local preset = self:_LoadAndLogJSON(filename, 'user')

        if preset then
            -- Check if already in registry (avoid duplicates from index)
            if not PresetRegistry.Get(preset._id) then
                if self:RegisterPreset(preset, "User", string.format("(Numbered: %01d)", i)) then
                    loadedCount = loadedCount + 1
                    PresetIndex.AddEntry(filename, preset._id, "User")
                end
            else
                CPFDebug(2, string.format("Preset %s already loaded, skipping numbered file %s", preset._id, filename))
            end
        else
            CPFPrint(1, string.format("No numbered user preset found at %s; stopping scan", filename))
            break
        end
    end

    if loadedCount > 0 then
        CPFPrint(2, string.format("Loaded %d numbered user preset(s)", loadedCount))
    end

    return loadedCount
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

    -- Load User Presets from Registry (including hidden ones)
    CPFPrint(1, "Loading user presets from registry...")
    local registryEntries = PresetIndex.Load()
    for _, entry in ipairs(registryEntries) do
        -- Load all presets, including hidden ones
        -- The UI will filter based on preset._indexData.hidden
        local preset = self:_LoadAndLogJSON(entry.filename, 'user')
        if preset then
            if self:RegisterPreset(preset, "User", "(Indexed)") then
                totalCount = totalCount + 1
            end
        end
    end

    -- Load 'Numbered User Presets' (preset_0.json to preset_9.json)
    local numberedCount = self:_LoadNumberedUserPresets()
    totalCount = totalCount + numberedCount

    CPFPrint(0, string.format("Preset discovery complete. Loaded %d preset(s) total.", totalCount))
    return totalCount
end

return PresetDiscovery
