DummyClient = {}

--- Returns the dummy based on a given entity
--- @param entity EntityHandle
--- @returns EntityHandle|nil
function DummyClient.GetDummyForEntity(entity)
    local dummyEntities = Ext.Entity.GetAllEntitiesWithComponent('CCChangeAppearanceDefinition')
    for _i, dummy in ipairs(dummyEntities) do
        ---@type EclCharacterCreationDummyDefinitionComponent
        local ccDummyDef = dummy.ClientCCDummyDefinition
        if ccDummyDef then
            local owner = ccDummyDef.field_1A8
            if owner and owner.Uuid and owner.Uuid.EntityUuid == entity.Uuid.EntityUuid then
                return dummy
            end
        end
    end

    return nil
end

return DummyClient
