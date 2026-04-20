---Server-side handlers for CPF NetChannels

---Handles ApplyPreset requests from clients
---@param data table
---@param userId integer
---@return table response
local function handleApplyPreset(data, userId)
    CPFPrint(1, "Received ApplyPreset request from client")
    CPFDumpCCA(2, data)

    local response = {
        Status = "success",
        AppliedAttributes = {},
        Warnings = {}
    }

    -- Validate input
    if not data.CharacterUuid or not data.Preset then
        response.Status = "error"
        table.insert(response.Warnings, Loca.Get(Loca.Keys.WARN_MISSING_DATA))
        return response
    end

    PresetCompat.NormalizePresetMetallicTint(data.Preset)

    -- -- If dry run, just return validation results
    -- if data.DryRun then
    --     response.Status = "success"
    --     response.AppliedAttributes = {}
    --     return response
    -- end

    local result = PresetApplication.Apply(data.CharacterUuid, data.Preset, {
        collectWarnings = true,
        autoEnterMirror = MCM.Get("auto_enter_mirror"),
        logSuccess = true,
    })

    if not result.Success then
        response.Status = "error"
        response.Warnings = result.Warnings or {}

        if result.ErrorCode == "INVALID_PRESET" then
            table.insert(response.Warnings, Loca.Format(Loca.Keys.WARN_INVALID_PRESET, result.ValidationError))
        elseif result.ErrorCode == "ENTITY_NOT_FOUND" then
            table.insert(response.Warnings, Loca.Get(Loca.Keys.WARN_ENTITY_NOT_FOUND))
        else
            table.insert(response.Warnings, result.Error)
        end

        return response
    end

    response.Warnings = result.Warnings or {}
    response.AppliedAttributes = result.AppliedAttributes or {}

    return response
end

local function initServerHandlers()
    NetChannels.RequestApplyPreset:SetRequestHandler(handleApplyPreset)
end

initServerHandlers()
