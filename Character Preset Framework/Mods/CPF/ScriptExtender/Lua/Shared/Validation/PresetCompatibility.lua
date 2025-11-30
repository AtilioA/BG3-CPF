---@class PresetCompatibility
PresetCompatibility = {}

--- Checks if preset stats are compatible with target stats
---@param presetStats CCStats
---@param targetStats CCStats|CharacterCreationStatsComponent
---@return string[] warnings
function PresetCompatibility.CheckStats(presetStats, targetStats)
    local warnings = {}

    if not presetStats or not targetStats then
        return warnings
    end

    -- Check BodyShape
    if presetStats.BodyShape and targetStats.BodyShape and presetStats.BodyShape ~= targetStats.BodyShape then
        table.insert(warnings,
            Loca.Format(Loca.Keys.COMPAT_WARN_BODY_SHAPE,
                ValueSerializer.Serialize(presetStats.BodyShape, "BodyShape"),
                ValueSerializer.Serialize(targetStats.BodyShape, "BodyShape")))
    end

    -- Check BodyType
    if presetStats.BodyType and targetStats.BodyType and presetStats.BodyType ~= targetStats.BodyType then
        table.insert(warnings,
            Loca.Format(Loca.Keys.COMPAT_WARN_BODY_TYPE,
                ValueSerializer.Serialize(presetStats.BodyType, "BodyType"),
                ValueSerializer.Serialize(targetStats.BodyType, "BodyType")))
    end

    -- Check Race
    if presetStats.Race and targetStats.Race and presetStats.Race ~= targetStats.Race then
        table.insert(warnings,
            Loca.Format(Loca.Keys.COMPAT_WARN_RACE,
                ValueSerializer.Serialize(presetStats.Race, "Race"),
                ValueSerializer.Serialize(targetStats.Race, "Race")))
    end

    -- Check SubRace
    if presetStats.SubRace and targetStats.SubRace and presetStats.SubRace ~= targetStats.SubRace then
        table.insert(warnings,
            Loca.Format(Loca.Keys.COMPAT_WARN_SUBRACE,
                ValueSerializer.Serialize(presetStats.SubRace, "Subrace"),
                ValueSerializer.Serialize(targetStats.SubRace, "Subrace")))
    end

    return warnings
end

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

    -- REFACTOR: allow comparing to CC dummy (does not have CharacterCreationStats)
    if not targetEntity or not targetEntity.CharacterCreationStats then
        CPFWarn(0, "PresetCompatibility.Check: Target entity is missing CharacterCreationStats")
        return warnings
    end

    return PresetCompatibility.CheckStats(preset.Data.CCStats, targetEntity.CharacterCreationStats)
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
