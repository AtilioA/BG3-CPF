---@class PresetCompatibility
PresetCompatibility = {}

--- Checks if a preset is compatible with the target entity
---@param preset Preset
---@param targetEntity EntityHandle
---@return string[] warnings
function PresetCompatibility.Check(preset, targetEntity)
    local warnings = {}

    if not preset or not preset.Data or not preset.Data.CCStats then
        CPFWarn(0, "PresetCompatibility.Check: Preset is missing CCStats")
        return warnings
    end

    if not targetEntity or not targetEntity.CharacterCreationStats then
        CPFWarn(0, "PresetCompatibility.Check: Target entity is missing CharacterCreationStats")
        return warnings
    end

    local presetStats = preset.Data.CCStats
    local targetStats = targetEntity.CharacterCreationStats

    if not presetStats or not targetStats then
        CPFWarn(0, "PresetCompatibility.Check: Preset or target entity is missing CCStats")
        return warnings
    end

    -- Check BodyShape
    if presetStats.BodyShape and targetStats.BodyShape and presetStats.BodyShape ~= targetStats.BodyShape then
        table.insert(warnings,
            string.format("Body Shape mismatch: Preset uses %s, Character uses %s.", tostring(presetStats.BodyShape),
                tostring(targetStats.BodyShape)))
    end

    -- Check BodyType
    if presetStats.BodyType and targetStats.BodyType and presetStats.BodyType ~= targetStats.BodyType then
        table.insert(warnings,
            string.format("Body Type mismatch: Preset uses %s, Character uses %s.", tostring(presetStats.BodyType),
                tostring(targetStats.BodyType)))
    end

    -- Check Race
    if presetStats.Race and targetStats.Race and presetStats.Race ~= targetStats.Race then
        table.insert(warnings,
            string.format("Race mismatch: Preset uses %s, Character uses %s.", tostring(presetStats.Race),
            tostring(targetStats.Race)))
    end

    -- Check SubRace
    if presetStats.SubRace and targetStats.SubRace and presetStats.SubRace ~= targetStats.SubRace then
        table.insert(warnings,
            string.format("Subrace mismatch: Preset uses %s, Character uses %s.", tostring(presetStats.SubRace),
                tostring(targetStats.SubRace)))
    end

    return warnings
end

--- Checks if required mods for a preset are loaded
---@param preset Preset
---@return string[] missingMods
function PresetCompatibility.CheckMods(preset)
    local missingMods = {}

    if not preset or not preset.Dependencies then
        return missingMods
    end

    for _, depEntry in ipairs(preset.Dependencies) do
        for modUUID, modInfo in pairs(depEntry) do
            if not Ext.Mod.IsModLoaded(modUUID) then
                table.insert(missingMods, string.format("%s (%s)", modInfo.Name or "Unknown Mod", modUUID))
            end
        end
    end

    return missingMods
end

return PresetCompatibility
