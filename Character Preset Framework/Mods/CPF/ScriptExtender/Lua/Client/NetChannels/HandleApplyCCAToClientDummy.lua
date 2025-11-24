---Client-side handler for applying CCA to ClientCCDummyDefinition

---Handles ApplyCCAToClientDummy messages from server
---@param data table - Contains CCATable to apply
---@param userId integer
local function handleApplyCCAToClientDummy(data, userId)
    CPFPrint(2, "Received request to apply CCA to client dummy")

    if not data.CCATable then
        CPFPrint(2, "No CCATable provided in request")
        return
    end

    -- Get the client-side dummy entity
    local dummyEntities = Ext.Entity.GetAllEntitiesWithComponent('ClientCCDummyDefinition')
    if not dummyEntities or #dummyEntities == 0 then
        CPFPrint(2, "No ClientCCDummyDefinition entity found")
        return
    end

    local DummyCCA = dummyEntities[1].CCChangeAppearanceDefinition.Appearance.Visual
    if not DummyCCA then
        CPFPrint(2, "ClientCCDummyDefinition component not found")
        return
    end

    -- Apply CCA table to dummy
    local copy = Table.deepcopy(data.CCATable)
    local successCount = 0
    local failCount = 0

    for k, v in pairs(copy) do
        local success, err = pcall(function() DummyCCA[k] = v end)
        if success then
            successCount = successCount + 1
        else
            failCount = failCount + 1
            CPFPrint(2, "Failed to set property " .. k .. " on DummyCCA: " .. tostring(err))
        end
    end

    CPFPrint(2, string.format("Applied CCA to client dummy: %d succeeded, %d failed", successCount, failCount))
end

local function initClientHandlers()
    NetChannels.ApplyCCAToClientDummy:SetHandler(handleApplyCCAToClientDummy)
end

initClientHandlers()
