---@class PresetDiscovery
--- Service for discovering and loading character presets from mod files
PresetDiscovery = {}

-- Pattern for preset file paths
PresetDiscovery.SinglePresetPathPattern = "Mods/%s/CPF_preset.json"
PresetDiscovery.MultiPresetPathPattern = "Mods/%s/CPF_presets.json"



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
    local loadedCount = 0

    CPFDebug(2, string.format("Checking mod '%s' for presets...", modName))

    -- Try to load single preset file (CPF_preset.json)
    local singlePresetPath = string.format(self.SinglePresetPathPattern, modDir)
    local singlePreset, singleErr = JsonLayer:Load(singlePresetPath)

    if not singlePreset then
        if singleErr and string.find(singleErr, "Parse error") then
            CPFWarn(0, "Failed to parse JSON file: " .. singlePresetPath)
        else
            CPFDebug(2, "JSON file not found: " .. singlePresetPath)
        end
    end

    if singlePreset then
        CPFPrint(1, string.format("Found CPF_preset.json in mod '%s'", modName))

        -- Validate and register the preset
        local valid, validErr = Preset.Validate(singlePreset)
        if valid then
            local success, regErr = PresetRegistry.Register(singlePreset)
            if success then
                loadedCount = loadedCount + 1
                CPFPrint(1, string.format("Loaded preset '%s' from mod '%s'", singlePreset.Name, modName))
            else
                CPFWarn(0, string.format("Failed to register preset from mod '%s': %s", modName, regErr))
            end
        else
            CPFWarn(0, string.format("Invalid preset in mod '%s': %s", modName, validErr))
        end
    end

    -- Try to load multiple presets file (CPF_presets.json)
    local multiPresetPath = string.format(self.MultiPresetPathPattern, modDir)
    local multiPresets, multiErr = JsonLayer:Load(multiPresetPath)

    if not multiPresets then
        if multiErr and string.find(multiErr, "Parse error") then
            CPFWarn(0, "Failed to parse JSON file: " .. multiPresetPath)
        else
            CPFDebug(2, "JSON file not found: " .. multiPresetPath)
        end
    end

    if multiPresets then
        CPFPrint(1, string.format("Found CPF_presets.json in mod '%s'", modName))

        -- Validate that it's an array
        if type(multiPresets) ~= "table" then
            CPFWarn(0, string.format("CPF_presets.json in mod '%s' is not a valid array", modName))
        else
            -- Check if it's an array (has numeric indices)
            local isArray = false
            for k, v in pairs(multiPresets) do
                if type(k) == "number" then
                    isArray = true
                    break
                end
            end

            if not isArray then
                CPFWarn(0, string.format("CPF_presets.json in mod '%s' is not a valid array", modName))
            else
                -- Iterate through presets
                for i, preset in ipairs(multiPresets) do
                    local valid, validErr = Preset.Validate(preset)
                    if valid then
                        local success, regErr = PresetRegistry.Register(preset)
                        if success then
                            loadedCount = loadedCount + 1
                            CPFPrint(1, string.format("Loaded preset '%s' from mod '%s' (index %d)", preset.Name, modName, i))
                        else
                            CPFWarn(0, string.format("Failed to register preset %d from mod '%s': %s", i, modName, regErr))
                        end
                    else
                        CPFWarn(0, string.format("Invalid preset %d in mod '%s': %s", i, modName, validErr))
                    end
                end
            end
        end
    end

    if loadedCount > 0 then
        CPFPrint(1, string.format("Loaded %d preset(s) from mod '%s'", loadedCount, modName))
    end

    return loadedCount
end

--- Loads all presets from all mods in the load order
---@return integer totalCount Total number of presets loaded
function PresetDiscovery:LoadPresets()
    CPFPrint(0, "Starting preset discovery...")

    local totalCount = 0
    local loadOrder = Ext.Mod.GetLoadOrder()

    if not loadOrder then
        CPFWarn(0, "Failed to get mod load order")
        return 0
    end

    -- Iterate through all mods in load order
    for _, modUUID in ipairs(loadOrder) do
        local modData = Ext.Mod.GetMod(modUUID)
        if modData then
            local count = self:LoadPresetsForMod(modData)
            totalCount = totalCount + count
        end
    end

    CPFPrint(0, string.format("Preset discovery complete. Loaded %d preset(s) total.", totalCount))
    return totalCount
end

return PresetDiscovery
