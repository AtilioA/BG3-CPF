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

    -- Validate preset structure
    local valid, validationErr = Preset.Validate(data.Preset)
    if not valid then
        response.Status = "error"
        table.insert(response.Warnings, Loca.Format(Loca.Keys.WARN_INVALID_PRESET, validationErr))
        return response
    end

    -- Get warnings about the preset
    local presetWarnings = Preset.GetWarnings(data.Preset)
    for _, warning in ipairs(presetWarnings) do
        table.insert(response.Warnings, warning)
    end

    -- -- If dry run, just return validation results
    -- if data.DryRun then
    --     response.Status = "success"
    --     response.AppliedAttributes = {}
    --     return response
    -- end

    -- Try to get the character entity
    local entity = Ext.Entity.Get(data.CharacterUuid)
    if not entity then
        response.Status = "error"
        table.insert(response.Warnings, Loca.Get(Loca.Keys.WARN_ENTITY_NOT_FOUND))
        return response
    end

    -- Apply preset data to character
    CCA.ApplyPresetData(entity, data.Preset.Data)

    -- Update character's appearance
    entity:Replicate("CharacterCreationAppearance")
    entity:Replicate("CharacterCreationStats")
    -- entity:Replicate("CustomIcon")
    -- entity:Replicate("Voice")

    -- Track which attributes were applied
    if data.Preset.Data and data.Preset.Data.CCAppearance then
        for key, _ in pairs(data.Preset.Data.CCAppearance) do
            table.insert(response.AppliedAttributes, key)
        end
    end

    local charName = Ext.Loca.GetTranslatedString(entity.DisplayName.NameKey.Handle.Handle)

    CPFPrint(1, string.format("Applied preset '%s' by %s to character %s",
        data.Preset.Name,
        data.Preset.Author,
        charName))

    -- Auto-enter mirror/appearance change mode if setting is enabled
    if MCM.Get("auto_enter_mirror") then
        CPFPrint(1, "Auto-entering mirror for " .. charName)
        Osi.StartChangeAppearance(data.CharacterUuid)
    end

    return response
end

local function initServerHandlers()
    NetChannels.RequestApplyPreset:SetRequestHandler(handleApplyPreset)
end

initServerHandlers()
