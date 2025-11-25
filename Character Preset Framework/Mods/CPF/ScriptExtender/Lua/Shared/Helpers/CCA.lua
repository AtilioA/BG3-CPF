CCA = {}

--- @param entity EntityHandle - Entity to copy CCA from
--- @return CharacterCreationAppearance? -- CCA component if found, nil if not found
function CCA.CopyCharacterCreationAppearance(entity)
    local CCA = entity.CharacterCreationAppearance
    if CCA then
        return Table.deepcopy(CCA)
    end
    return nil
end

--- @param entity EntityHandle - Entity to copy dummy appearance from
--- @return CharacterCreationAppearance? -- Dummy appearance if found, nil if not found
function CCA.CopyDummyAppearance(entity)
    local dummyCCA = entity.ClientCCDummyDefinition
    if dummyCCA and dummyCCA.Visual then
        local vis = dummyCCA.Visual
        return Table.deepcopy(vis)
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

    -- local CCADummies = Ext.Entity.GetAllEntitiesWithComponent('CCChangeAppearanceDefinition')
    -- if not CCADummies or #CCADummies == 0 then
    --     CPFPrint(2, "No CCChangeAppearanceDefinition entity found")
    --     return
    -- end
    -- if CCADummies[1] then
    --     local dummyCCA = CCADummies[1].CCChangeAppearanceDefinition
    --     local dummyCCADA = dummyCCA.Appearance
    --     if dummyCCADA and dummyCCADA.Visual then
    --         local vis = dummyCCADA.Visual
    --         local copy = Table.deepcopy(CCATable)
    --         for k, v in pairs(copy) do
    --             local success, err = pcall(function() vis[k] = v end)
    --             -- TODO: Add missing fields to CCA somehow?
    --             if not success then
    --                 CPFPrint(2, "Failed to set property " .. k .. " on dummyCCADA: " .. tostring(err))
    --             end
    --         end
    --     end
    --     local dummyCCADV = dummyCCA.Definition
    --     if dummyCCADV and dummyCCADV.Visual then
    --         local vis = dummyCCADV.Visual
    --         local copy = Table.deepcopy(CCATable)
    --         for k, v in pairs(copy) do
    --             local success, err = pcall(function() vis[k] = v end)
    --             -- TODO: Add missing fields to CCA somehow?
    --             if not success then
    --                 CPFPrint(2, "Failed to set property " .. k .. " on dummyCCADV: " .. tostring(err))
    --             end
    --         end
    --     end

    --     CCADummies[1]:Replicate("CCChangeAppearanceDefinition")
    -- end

    -- Send CCA table to client to apply to dummy (only on server)
    if Ext.IsServer() then
        NetChannels.ApplyCCAToClientDummy:Broadcast({
            CCATable = CCATable
        })
        CPFPrint(2, "Sent CCA table to client for dummy application")
    end
end
