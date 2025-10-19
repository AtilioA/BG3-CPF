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
            CCA[k] = v
        end
    end
end
