CPFPrinter = Printer:New { Prefix = "Character Preset Framework", ApplyColor = true, DebugLevel = MCM.Get("debug_level") }

-- Update the Printer debug level when the setting is changed, since the value is only used during the object's creation
Ext.ModEvents.BG3MCM['MCM_Setting_Saved']:Subscribe(function(payload)
    if not payload or payload.modUUID ~= ModuleUUID or not payload.settingId then
        return
    end

    if payload.settingId == "debug_level" then
        CPFDebug(0, "Setting debug level to " .. payload.value)
        CPFPrinter.DebugLevel = payload.value
    end
end)

function CPFPrint(debugLevel, ...)
    CPFPrinter:SetFontColor(0, 255, 255)
    CPFPrinter:Print(debugLevel, ...)
end

function CPFTest(debugLevel, ...)
    CPFPrinter:SetFontColor(100, 200, 150)
    CPFPrinter:PrintTest(debugLevel, ...)
end

function CPFDebug(debugLevel, ...)
    CPFPrinter:SetFontColor(200, 200, 0)
    CPFPrinter:PrintDebug(debugLevel, ...)
end

function CPFWarn(debugLevel, ...)
    CPFPrinter:SetFontColor(255, 100, 50)
    CPFPrinter:PrintWarning(debugLevel, ...)
end

function CPFDump(...)
    CPFPrinter:SetFontColor(190, 150, 225)
    CPFPrinter:Dump(...)
end

function CPFDumpArray(...)
    CPFPrinter:DumpArray(...)
end

--- @param debugLevel integer
--- @param cca CharacterCreationAppearanceComponent
function CPFDumpCCA(debugLevel, cca)
    CPFPrinter:SetFontColor(190, 150, 225)
    DumpCCA(debugLevel, cca)
end

-- Internal: Resource manager type names we care about for CCA resolution
local CCA_RES_TYPES = {
    AccessorySet = "CharacterCreationAccessorySet",
    AppearanceMaterial = "CharacterCreationAppearanceMaterial",
    AppearanceVisual = "CharacterCreationAppearanceVisual",
    EyeColor = "CharacterCreationEyeColor",
    HairColor = "CharacterCreationHairColor",
    SkinColor = "CharacterCreationSkinColor",
}

---@param data table|nil
---@return string|nil
local function _extractStaticName(data)
    if not data then return nil end
    -- Try common name-like fields in order of usefulness
    local candidates = { "Name", "SlotName", "DisplayName" }
    for _, k in ipairs(candidates) do
        local v = UserData.Get(data, k)
        if type(v) == "string" and v ~= "" then
            return v
        end
    end
    return nil
end

---@param guid string|nil
---@param typeName string
---@return table|nil
local function _tryStaticData(guid, typeName)
    if not guid or guid == "" then return nil end
    local ok, result = pcall(Ext.StaticData.Get, guid, typeName)
    if ok and result ~= nil then
        return result
    end
    return nil
end

---@param guid string|nil
---@param typeName string
---@return table
local function _formatResolvedGuid(guid, typeName)
    if not guid or guid == "" then
        return {}
    end
    local data = _tryStaticData(guid, typeName)
    local name = _extractStaticName(data)
    if not name then name = "Unknown" end
    return {
        Guid = guid,
        -- Type = typeName,
        Name = name,
        -- Data = nil, -- Avoid dumping entire static objects by default (can be huge)
    }
end

---@param setting CharacterCreationAppearanceMaterialSetting|table|nil
---@return table
local function _summarizeMaterialSetting(setting)
    if not setting then
        return { Error = "Material setting is nil" }
    end
    return {
        Material = _formatResolvedGuid(setting.Material, CCA_RES_TYPES.AppearanceMaterial),
        Color = tostring(setting.Color or ""),
        ColorIntensity = setting.ColorIntensity or 0,
        GlossyTint = setting.GlossyTint or 0,
        MetallicTint = setting.MetallicTint or 0,
    }
end

---@param debugLevel integer
---@param safeCCA CharacterCreationAppearanceComponent|table|nil
---@param options table|nil @optional flags: { includeDeepStatic:boolean }
---@return nil
function DumpCCA(debugLevel, cca, options)
    if not cca then
        CPFWarn(0, "DumpCCA called with nil CCA")
        return
    end

    -- TODO: move this
    if debugLevel > CPFPrinter.DebugLevel then
        return
    end

    -- Allows safely accessing CCA userdata properties without errors
    local safeCCA = UserData.Safe(cca)

    ---@type table
    local summary = {
        AccessorySet = _formatResolvedGuid(safeCCA.AccessorySet, CCA_RES_TYPES.AccessorySet),
        EyeColor = _formatResolvedGuid(safeCCA.EyeColor, CCA_RES_TYPES.EyeColor),
        SecondEyeColor = _formatResolvedGuid(safeCCA.SecondEyeColor, CCA_RES_TYPES.EyeColor),
        HairColor = _formatResolvedGuid(safeCCA.HairColor, CCA_RES_TYPES.HairColor),
        SkinColor = _formatResolvedGuid(safeCCA.SkinColor, CCA_RES_TYPES.SkinColor),
        field_98 = tostring(safeCCA.field_98 or ""),
        AdditionalChoices = {},
        Visuals = {},
        Elements = {},
        Icon = safeCCA.Icon and "<ScratchBuffer>" or nil,
    }

    -- AdditionalChoices (map indices to names)
    summary.AdditionalChoices = CCAEnums.MapAdditionalChoices(safeCCA.AdditionalChoices)

    -- Elements (material-related, etc?)
    summary.Elements = CCAEnums.MapElements(safeCCA.Elements)

    -- Visuals
    if safeCCA.Visuals then
        for _, v in ipairs(safeCCA.Visuals) do
            table.insert(summary.Visuals, _formatResolvedGuid(v, CCA_RES_TYPES.AppearanceVisual))
        end
    end

    CPFPrinter:SetFontColor(190, 150, 225) -- Light purple (same as CPFDump)
    CPFPrinter:Dump(summary)
end
