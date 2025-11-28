---Client-side handler for applying preset data to client dummies

-- Thanks rakor and Skiz for this!
local function refreshMirrorDummy()
    -- Doesn't seem to work in CC!
    VCTimer:OnTicks(10, function()
        pcall(function()
            CPFPrint(2, "Refreshing CC dummy")
            Ext.UI.GetRoot():Child(1):Child(1):Child(24):Child(1).StartCharacterCreation:Execute()
        end)
    end)
end

--- Get all relevant dummy entities (from CCChangeAppearanceDefinition and ClientCCDummyDefinition)
---@return EntityHandle[] dummyEntities
local function GetDummyEntities()
    local dummies = {}

    -- Get all CCChangeAppearanceDefinition entities
    local ccChangeAppearanceEntities = Ext.Entity.GetAllEntitiesWithComponent('CCChangeAppearanceDefinition')
    if ccChangeAppearanceEntities then
        for _, entity in ipairs(ccChangeAppearanceEntities) do
            table.insert(dummies, entity)
        end
    end

    -- Get ClientCCDummyDefinition entity (specifically index 2?)
    local ccDummyEntities = Ext.Entity.GetAllEntitiesWithComponent('ClientCCDummyDefinition')
    if ccDummyEntities and ccDummyEntities[2] then
        table.insert(dummies, ccDummyEntities[2])
    end

    return dummies
end

--- Extract CCStats-compatible stats from a dummy entity
---@param entity EntityHandle
---@return CCStats|nil
local function ExtractDummyStats(entity)
    -- Try ClientCCDummyDefinition first
    if entity.ClientCCDummyDefinition then
        local def = entity.ClientCCDummyDefinition
        if def.BodyShape ~= nil and def.BodyType ~= nil and def.Race and def.Subrace then
            return {
                BodyShape = def.BodyShape,
                BodyType = def.BodyType,
                Race = def.Race,
                SubRace = def.Subrace
            }
        end
    end

    -- Try ClientCCChangeAppearanceDefinition
    if entity.ClientCCChangeAppearanceDefinition and entity.ClientCCChangeAppearanceDefinition.Definition then
        local def = entity.ClientCCChangeAppearanceDefinition.Definition
        if def.BodyShape ~= nil and def.BodyType ~= nil and def.Race and def.Subrace then
            return {
                BodyShape = def.BodyShape,
                BodyType = def.BodyType,
                Race = def.Race,
                SubRace = def.Subrace
            }
        end
    end

    -- Try CCChangeAppearanceDefinition
    if entity.CCChangeAppearanceDefinition and entity.CCChangeAppearanceDefinition.Definition then
        local def = entity.CCChangeAppearanceDefinition.Definition
        if def.BodyShape ~= nil and def.BodyType ~= nil and def.Race and def.Subrace then
            return {
                BodyShape = def.BodyShape,
                BodyType = def.BodyType,
                Race = def.Race,
                SubRace = def.Subrace
            }
        end
    end

    return nil
end

--- Apply visuals to a dummy entity, trying all known paths
---@param entity EntityHandle
---@param ccaTable CharacterCreationAppearance
---@return integer successCount
---@return integer failCount
local function ApplyVisualsToDummy(entity, ccaTable)
    -- Define all possible paths to try for accessing the Visual component
    local pathsToTry = {
        {
            name = "CCChangeAppearanceDefinition.Appearance.Visual",
            getter = function(e)
                return e.CCChangeAppearanceDefinition and
                    e.CCChangeAppearanceDefinition.Appearance and
                    e.CCChangeAppearanceDefinition.Appearance.Visual
            end
        },
        {
            name = "CCChangeAppearanceDefinition.Definition.Visual",
            getter = function(e)
                return e.CCChangeAppearanceDefinition and
                    e.CCChangeAppearanceDefinition.Definition and
                    e.CCChangeAppearanceDefinition.Definition.Visual
            end
        },
        {
            name = "ClientCCChangeAppearanceDefinition.Definition.Visual",
            getter = function(e)
                return e.ClientCCChangeAppearanceDefinition and
                    e.ClientCCChangeAppearanceDefinition.Definition and
                    e.ClientCCChangeAppearanceDefinition.Definition.Visual
            end
        },
        {
            name = "ClientCCDummyDefinition.Visual",
            getter = function(e)
                return e.ClientCCDummyDefinition and
                    e.ClientCCDummyDefinition.Visual
            end
        },
    }

    local totalSuccessCount = 0
    local totalFailCount = 0
    local pathsAttempted = 0

    -- Try each path
    for _, path in ipairs(pathsToTry) do
        local visual = path.getter(entity)

        if visual then
            CPFPrint(2, "Found Visual at path: " .. path.name)
            pathsAttempted = pathsAttempted + 1

            -- Apply CCA table to this visual
            local copy = Table.deepcopy(ccaTable)
            local successCount = 0
            local failCount = 0

            for k, v in pairs(copy) do
                local success, err = pcall(function() visual[k] = v end)
                if success then
                    successCount = successCount + 1
                else
                    failCount = failCount + 1
                    CPFPrint(2, string.format("Failed to set property %s on %s: %s", k, path.name, tostring(err)))
                end
            end

            totalSuccessCount = totalSuccessCount + successCount
            totalFailCount = totalFailCount + failCount

            CPFPrint(2, string.format("Path %s: %d succeeded, %d failed", path.name, successCount, failCount))
        end
    end

    if pathsAttempted == 0 then
        CPFPrint(2, "No valid Visual paths found on dummy entity")
    end

    return totalSuccessCount, totalFailCount
end

---Handles ApplyCCAToClientDummy messages from server
---@param data table - Contains PresetData to apply
---@param userId integer
local function handleApplyCCAToClientDummy(data, userId)
    CPFPrint(2, "Received request to apply preset data to client dummy")

    if not data.PresetData then
        CPFPrint(2, "No PresetData provided in request")
        return
    end

    local presetData = data.PresetData
    if not presetData.CCAppearance then
        CPFPrint(2, "PresetData is missing CCAppearance")
        return
    end

    -- Get all dummy entities
    local dummyEntities = GetDummyEntities()
    if #dummyEntities == 0 then
        CPFPrint(2, "No dummy entities found")
        return
    end

    local totalSuccessCount = 0
    local totalFailCount = 0
    local entitiesProcessed = 0

    -- Process each dummy entity
    for _, entity in ipairs(dummyEntities) do
        -- Extract stats from dummy for compatibility check
        local dummyStats = ExtractDummyStats(entity)

        -- Check compatibility if we have both preset and dummy stats
        if presetData.CCStats and dummyStats and PresetCompatibility then
            local warnings = PresetCompatibility.CheckStats(presetData.CCStats, dummyStats)

            if #warnings > 0 then
                CPFPrint(2, "Compatibility warnings for dummy entity:")
                for _, warning in ipairs(warnings) do
                    CPFPrint(2, "  - " .. warning)
                end
                -- CPFPrint(2, "Skipping visual application for this dummy due to incompatibility")
                -- goto continue
            end
        end

        -- Apply visuals to this dummy
        local successCount, failCount = ApplyVisualsToDummy(entity, presetData.CCAppearance)
        totalSuccessCount = totalSuccessCount + successCount
        totalFailCount = totalFailCount + failCount

        if successCount > 0 or failCount > 0 then
            entitiesProcessed = entitiesProcessed + 1
        end

        ::continue::
    end

    if entitiesProcessed == 0 then
        CPFPrint(2, "No compatible dummy entities found to apply visuals")
        return
    end

    CPFPrint(2, string.format("Applied preset data to %d dummy entities: %d total succeeded, %d total failed",
        entitiesProcessed, totalSuccessCount, totalFailCount))
    refreshMirrorDummy()
end

local function initClientHandlers()
    NetChannels.ApplyCCAToClientDummy:SetHandler(handleApplyCCAToClientDummy)
end

initClientHandlers()
