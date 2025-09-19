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

function CPFDump(debugLevel, ...)
    CPFPrinter:SetFontColor(190, 150, 225)
    CPFPrinter:Dump(debugLevel, ...)
end

function CPFDumpArray(debugLevel, ...)
    CPFPrinter:DumpArray(debugLevel, ...)
end

--- @param debugLevel integer
--- @param cca CharacterCreationAppearanceComponent
function CPFDumpCCA(debugLevel, cca)
    CPFPrinter:SetFontColor(190, 150, 225)
    CPFDumpCCA(debugLevel, cca)
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
    local candidates = { "Name", "DisplayName" }
    for _, k in ipairs(candidates) do
        local v = data[k]
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
        return { Guid = guid or "", Resolved = nil, Type = typeName }
    end
    local data = _tryStaticData(guid, typeName)
    local name = _extractStaticName(data)
    return {
        Guid = guid,
        Type = typeName,
        Name = name,
        Data = nil, -- Avoid dumping entire static objects by default (can be huge)
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
---@param cca CharacterCreationAppearanceComponent|table|nil
---@param options table|nil @optional flags: { includeDeepStatic:boolean }
---@return nil
function CPFDumpCCA(debugLevel, cca, options)
    if not cca then
        CPFWarn(0, "CPFDumpCCA called with nil CCA")
        return
    end

    local includeDeepStatic = options and options.includeDeepStatic == true

    ---@type table
    local summary = {
        AccessorySet = UserData.TryGetFallback(cca, "AccessorySet", nil) and _formatResolvedGuid(cca.AccessorySet, CCA_RES_TYPES.AccessorySet),
        EyeColor = UserData.TryGetFallback(cca, "EyeColor", nil) and _formatResolvedGuid(cca.EyeColor, CCA_RES_TYPES.EyeColor),
        SecondEyeColor = UserData.TryGetFallback(cca, "SecondEyeColor", nil) and _formatResolvedGuid(cca.SecondEyeColor, CCA_RES_TYPES.EyeColor),
        HairColor = UserData.TryGetFallback(cca, "HairColor", nil) and _formatResolvedGuid(cca.HairColor, CCA_RES_TYPES.HairColor),
        SkinColor = UserData.TryGetFallback(cca, "SkinColor", nil) and _formatResolvedGuid(cca.SkinColor, CCA_RES_TYPES.SkinColor),
        field_98 = tostring(cca.field_98 or ""),
        AdditionalChoices = {},
        Visuals = {},
        Elements = {},
        Icon = cca.Icon and "<ScratchBuffer>" or nil,
    }

    -- AdditionalChoices
    if type(cca.AdditionalChoices) == "table" then
        for _, n in ipairs(cca.AdditionalChoices) do
            table.insert(summary.AdditionalChoices, n)
        end
    end

    -- Visuals
    if type(cca.Visuals) == "table" then
        for _, v in ipairs(cca.Visuals) do
            table.insert(summary.Visuals, _formatResolvedGuid(v, CCA_RES_TYPES.AppearanceVisual))
        end
    end

    -- Elements (materials)
    if type(cca.Elements) == "table" then
        for _, el in ipairs(cca.Elements) do
            table.insert(summary.Elements, _summarizeMaterialSetting(el))
        end
    end

    -- Optionally include the full static data blobs for power users
    if includeDeepStatic then
        local deep = {}
        deep.AccessorySet = _tryStaticData(cca.AccessorySet, CCA_RES_TYPES.AccessorySet)
        deep.EyeColor = _tryStaticData(cca.EyeColor, CCA_RES_TYPES.EyeColor)
        deep.SecondEyeColor = _tryStaticData(cca.SecondEyeColor, CCA_RES_TYPES.EyeColor)
        deep.HairColor = _tryStaticData(cca.HairColor, CCA_RES_TYPES.HairColor)
        deep.SkinColor = _tryStaticData(cca.SkinColor, CCA_RES_TYPES.SkinColor)
        deep.Visuals = {}
        if type(cca.Visuals) == "table" then
            for i, v in ipairs(cca.Visuals) do
                deep.Visuals[i] = _tryStaticData(v, CCA_RES_TYPES.AppearanceVisual)
            end
        end
        deep.Materials = {}
        if type(cca.Elements) == "table" then
            for i, el in ipairs(cca.Elements) do
                deep.Materials[i] = _tryStaticData(el and el.Material or nil, CCA_RES_TYPES.AppearanceMaterial)
            end
        end
        summary.DeepStatic = deep
    end

    CPFPrinter:SetFontColor(190, 150, 225) -- Light purple (same as CPFDump)
    CPFPrinter:Dump(debugLevel, { CharacterCreationAppearance = summary })
end
