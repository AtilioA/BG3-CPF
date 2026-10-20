--- Applies preset CCStats (Race, SubRace, BodyShape, BodyType) to characters.
--- Photography-oriented: changing these stats on an existing character may break saves.
--- Only invoked when the "apply_race_and_body" MCM toggle is enabled.
CCStatsApplier = {}

---@param entity EntityHandle
---@param ccStats CCStats
function CCStatsApplier.ApplyToEntity(entity, ccStats)
    local stats = entity.CharacterCreationStats
    stats.BodyShape = ccStats.BodyShape
    stats.BodyType = ccStats.BodyType
    stats.Race = ccStats.Race
    stats.SubRace = ccStats.SubRace

    CPFPrint(2, "CCStatsApplier: Applied CCStats to entity " .. entity.Uuid.EntityUuid)
end

return CCStatsApplier
