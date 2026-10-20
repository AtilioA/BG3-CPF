---Applies preset CCStats (Race, SubRace, BodyShape, BodyType) to mirror/CC dummies, so the dummy updates with the preset stats (photography race/body swap).
CCStatsApplier = {}

---@param dummyEntities EntityHandle[]
---@param ccStats CCStats
function CCStatsApplier.ApplyToDummies(dummyEntities, ccStats)
    for _, entity in ipairs(dummyEntities) do
        -- Only the dummy definition carries Race/Subrace; the change-appearance definitions do not.
        local def = entity.ClientCCDummyDefinition
        if def then
            def.BodyShape = ccStats.BodyShape
            def.BodyType = ccStats.BodyType
            def.Race = ccStats.Race
            def.Subrace = ccStats.SubRace
        end
    end
end

return CCStatsApplier
