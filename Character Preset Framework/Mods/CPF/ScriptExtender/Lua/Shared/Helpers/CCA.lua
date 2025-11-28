-- FIXME: remove client-side code from here (dummy-related)
-- Also decouple unrelated things

CCA = {}

--- Returns whether the client is currently in the Character Creation level
---@return boolean
function CCA.IsInCC()
    if Ext.IsServer() then return false end
    local level = _C().Level
    return level and level.LevelName == "SYS_CC_I"
end

--- Returns the CC Dummy entity if in CC
---@return EntityHandle|nil
function CCA.GetCCDummy()
    if not CCA.IsInCC() then return nil end
    -- In CC, the dummy is usually the second entity with ClientCCDummyDefinition (?)
    -- This may not be correct but seems to work; might not work for multiplayer.
    local entities = Ext.Entity.GetAllEntitiesWithComponent('ClientCCDummyDefinition')
    return entities and entities[2]
end

--- Return whether entity has a dummy in CC/Mirror
---@param entity EntityHandle
---@return boolean
function CCA.HasDummy(entity)
    if not entity then return false end
    if not entity.CCState then
        return false
    end
    return entity.CCState.HasDummy
end

--- Extracts data from the Character Creation Dummy
---@return PresetData|nil
function CCA.ExtractFromCC()
    local dummy = CCA.GetCCDummy()
    if not dummy or not dummy.ClientCCDummyDefinition then
        CPFDebug(1, "CCA.ExtractFromCC: No CC dummy found")
        return nil
    end

    local def = dummy.ClientCCDummyDefinition
    if not def then
        CPFWarn(1, "Dummy has no ClientCCDummyDef")
        return nil
    end

    local stats = {
        BodyShape = def.BodyShape,
        BodyType = def.BodyType,
        Race = def.Race,
        SubRace = def.Subrace or "",
        -- Origin = def.Origin,
    }

    local appearance = nil
    if def.Visual then
        appearance = Table.deepcopy(def.Visual)
    end

    return {
        CCStats = stats,
        CCAppearance = appearance
    }
end

--- Extracts data from a Mirror Dummy
---@param entity EntityHandle
---@return PresetData|nil
function CCA.ExtractFromMirror(entity)
    if Ext.IsServer() then
        CPFWarn(1, "Trying to get dummy appearance on server!")
        return nil
    end

    local dummy = DummyClient.GetDummyForEntity(entity)
    if not dummy or not dummy.ClientCCDummyDefinition then
        CPFDebug(1, "CCA.ExtractFromMirror: No dummy found for entity " .. entity.Uuid.EntityUuid)
        return nil
    end

    local def = dummy.ClientCCDummyDefinition
    if not def then
        CPFWarn(1, "Dummy has no ClientCCDummyDef")
        return nil
    end

    local stats = {
        BodyShape = def.BodyShape,
        BodyType = def.BodyType,
        Race = def.Race,
        SubRace = def.Subrace or ""
    }

    local appearance = nil
    if def.Visual then
        appearance = Table.deepcopy(def.Visual)
    end

    return {
        CCStats = stats,
        CCAppearance = appearance
    }
end

--- Extracts data from a regular Gameplay Entity
---@param entity EntityHandle
---@return PresetData|nil
function CCA.ExtractFromEntity(entity)
    if not entity then return nil end

    local stats = entity.CharacterCreationStats
    if not stats then
        CPFWarn(0, "Entity has no CharacterCreationStats")
    end

    local ccStats = nil
    if stats then
        ccStats = {
            BodyShape = stats.BodyShape,
            BodyType = stats.BodyType,
            Race = stats.Race,
            SubRace = stats.SubRace
        }
    end

    local appearance = entity.CharacterCreationAppearance
    local ccAppearance = nil
    if appearance then
        ccAppearance = Table.deepcopy(appearance)
    end

    return {
        CCStats = ccStats,
        CCAppearance = ccAppearance
    }
end

--- Main entry point to extract data from any source (CC, Mirror, or Entity)
---@param entity EntityHandle
---@return PresetData|nil
function CCA.ExtractData(entity)
    -- Case 1: Character Creation
    if CCA.IsInCC() then
        CPFDebug(1, "CCA.ExtractData: Extracting from CC Dummy")
        return CCA.ExtractFromCC()
    end

    -- Case 2: Mirror (Has Dummy)
    if CCA.HasDummy(entity) then
        CPFDebug(1, "CCA.ExtractData: Extracting from Mirror Dummy")
        return CCA.ExtractFromMirror(entity)
    end

    -- Case 3: Regular Entity
    CPFDebug(1, "CCA.ExtractData: Extracting from Entity")
    return CCA.ExtractFromEntity(entity)
end

-- Deprecated: Use CCA.ExtractData instead
function CCA.CopyCharacterCreationAppearance(entity)
    local data = CCA.ExtractData(entity)
    return data and data.CCAppearance
end

--- Applies preset data (appearance + stats) to a character entity and broadcasts to client
--- @param charEntity EntityHandle
--- @param presetData PresetData - Contains CCStats and CCAppearance
--- @return nil
function CCA.ApplyPresetData(charEntity, presetData)
    CPFPrint(2, "Applying preset data to character " .. VCLoca:GetDisplayName(charEntity))

    if not presetData or not presetData.CCAppearance then
        CPFWarn(0, "CCA.ApplyPresetData: PresetData is missing CCAppearance")
        return
    end

    local CCA = charEntity.CharacterCreationAppearance
    if CCA then
        local copy = Table.deepcopy(presetData.CCAppearance)
        for k, v in pairs(copy) do
            local success, err = pcall(function() CCA[k] = v end)
            -- TODO: Add missing fields to CCA somehow?
            if not success then
                CPFPrint(2, "Failed to set property " .. k .. " on CCA: " .. tostring(err))
            end
        end
    end

    -- Send preset data to client to apply to dummy (only on server)
    if Ext.IsServer() then
        NetChannels.ApplyCCAToClientDummy:Broadcast({
            PresetData = presetData
        })
        CPFPrint(2, "Sent preset data to client for dummy application")
    end
end
