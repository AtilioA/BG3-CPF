---Client-side handler for applying CCA to ClientCCDummyDefinition

-- Thanks rakor and Skiz for this!
local function refreshCCDummy()
    pcall(function() Ext.UI.GetRoot():Child(1):Child(1):Child(24):Child(1).StartCharacterCreation:Execute() end)
end

---Handles ApplyCCAToClientDummy messages from server
---@param data table - Contains CCATable to apply
---@param userId integer
local function handleApplyCCAToClientDummy(data, userId)
    CPFPrint(2, "Received request to apply CCA to client dummy")

    if not data.CCATable then
        CPFPrint(2, "No CCATable provided in request")
        return
    end

    -- TODO: only edit the one that matches userId's character
    -- Get the client-side dummy entity
    -- Search for entities with CCChangeAppearanceDefinition
    local dummyEntities = Ext.Entity.GetAllEntitiesWithComponent('CCChangeAppearanceDefinition')

    if not dummyEntities or #dummyEntities == 0 then
        CPFPrint(2, "No CCChangeAppearanceDefinition entity found")
        return
    end

    -- Define all possible paths to try for accessing the Visual component
    local pathsToTry = {
        {
            name = "CCChangeAppearanceDefinition.Appearance.Visual",
            getter = function(entity)
                return entity.CCChangeAppearanceDefinition and
                    entity.CCChangeAppearanceDefinition.Appearance and
                    entity.CCChangeAppearanceDefinition.Appearance.Visual
            end
        },
        {
            name = "CCChangeAppearanceDefinition.Definition.Visual",
            getter = function(entity)
                return entity.CCChangeAppearanceDefinition and
                    entity.CCChangeAppearanceDefinition.Definition and
                    entity.CCChangeAppearanceDefinition.Definition.Visual
            end
        },
        {
            name = "ClientCCChangeAppearanceDefinition.Definition.Visual",
            getter = function(entity)
                return entity.ClientCCChangeAppearanceDefinition and
                    entity.ClientCCChangeAppearanceDefinition.Definition and
                    entity.ClientCCChangeAppearanceDefinition.Definition.Visual
            end
        },
        {
            name = "ClientCCDummyDefinition.Visual",
            getter = function(entity)
                return entity.ClientCCDummyDefinition and
                    entity.ClientCCDummyDefinition.Visual
            end
        }
    }

    local totalSuccessCount = 0
    local totalFailCount = 0
    local pathsAttempted = 0

    -- Try each path
    for _, path in ipairs(pathsToTry) do
        local visual = path.getter(dummyEntities[1])

        if visual then
            CPFPrint(2, "Found Visual at path: " .. path.name)
            pathsAttempted = pathsAttempted + 1

            -- Apply CCA table to this visual
            local copy = Table.deepcopy(data.CCATable)
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
        else
            CPFPrint(2, "Path not found: " .. path.name)
        end
    end

    if pathsAttempted == 0 then
        CPFPrint(2, "No valid Visual paths found on dummy entity")
        return
    end

    CPFPrint(2, string.format("Applied CCA to client dummy across %d paths: %d total succeeded, %d total failed",
        pathsAttempted, totalSuccessCount, totalFailCount))
    refreshCCDummy()
end

local function initClientHandlers()
    NetChannels.ApplyCCAToClientDummy:SetHandler(handleApplyCCAToClientDummy)
end

initClientHandlers()
