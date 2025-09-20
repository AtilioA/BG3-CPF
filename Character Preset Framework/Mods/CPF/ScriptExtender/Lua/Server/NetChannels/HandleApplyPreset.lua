---Server-side handlers for CPF NetChannels

---Handles ApplyPreset requests from clients
---@param data table
---@param userId integer
---@return table response
local function handleApplyPreset(data, userId)
    -- TODO: Implement preset application logic
    local response = {
        Status = "success",
        AppliedAttributes = {},
        Warnings = {}
    }

    return response
end

local function initServerHandlers()
    NetChannels.RequestApplyPreset:SetRequestHandler(handleApplyPreset)
end

initServerHandlers()
