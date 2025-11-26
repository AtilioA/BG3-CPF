-- FIXME: remove client-side code from here (dummy-related)

CCA = {}

--- Return whether entity has a dummy in CC/Mirror
---@param entity EntityHandle
---@return boolean
function CCA.HasDummy(entity)
    if not entity.CCState then
        return false
    end
    return entity.CCState.HasDummy
end

--- @param entity EntityHandle - Entity to copy CCA from
--- @return CharacterCreationAppearance? -- CCA component if found, nil if not found
function CCA.CopyCharacterCreationAppearance(entity)
    --- Copy from dummy if dummy has been found
    local CCA = entity.CharacterCreationAppearance
    if CCA then
        return Table.deepcopy(CCA)
    end
    return nil
end

function CCA.CopyCCAOrDummy(entity)
    --- Copy from dummy instead if dummy has been found
    if CCA.HasDummy(entity) then
        CPFDebug(1, "Entity has dummy, copying from it instead")
        _D(entity)
        return CCA.CopyDummyAppearance(entity)
    end

    CPFDebug(1, "Entity has no dummy, copying from CCA")
    local CCA = entity.CharacterCreationAppearance
    if CCA then
        return Table.deepcopy(CCA)
    end
    return nil
end

--- @param entity EntityHandle - Entity to copy dummy appearance from
--- @return CharacterCreationAppearance? -- Dummy appearance if found, nil if not found
function CCA.CopyDummyAppearance(entity)
    if Ext.IsServer() then
        CPFWarn(1, "Trying to get dummy appearance on server!")
        return
    end

    local dummy = DummyClient.GetDummyForEntity(entity)
    if not dummy then
        CPFWarn(0, "No dummy found for entity " .. entity.Uuid.EntityUuid)
        return
    end

    if dummy.ClientCCDummyDefinition and dummy.ClientCCDummyDefinition.Visual then
        return Table.deepcopy(dummy.ClientCCDummyDefinition and dummy.ClientCCDummyDefinition.Visual)
    end

    return nil
end

--- Applies all values from CCATable to the CCA component of charEntity (NOTE: not replicated; must coordinate with server)
--- @param charEntity EntityHandle
--- @param CCATable CharacterCreationAppearance
--- @return nil
function CCA.ApplyCCATable(charEntity, CCATable)
    CPFPrint(2, "Applying CCA table to character " .. VCLoca:GetDisplayName(charEntity))
    local CCA = charEntity.CharacterCreationAppearance
    if CCA then
        local copy = Table.deepcopy(CCATable)
        for k, v in pairs(copy) do
            local success, err = pcall(function() CCA[k] = v end)
            -- TODO: Add missing fields to CCA somehow?
            if not success then
                CPFPrint(2, "Failed to set property " .. k .. " on CCA: " .. tostring(err))
            end
        end
    end

    -- Send CCA table to client to apply to dummy (only on server)
    if Ext.IsServer() then
        NetChannels.ApplyCCAToClientDummy:Broadcast({
            CCATable = CCATable
        })
        CPFPrint(2, "Sent CCA table to client for dummy application")
    end
end
