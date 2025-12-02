local State = Ext.Require("Client/UI/State.lua")
local MessageBox = Ext.Require("Client/UI/Components/MessageBox.lua")
local PresetInspector = Ext.Require("Shared/Presets/PresetInspector.lua")
local PresetCompatibility = Ext.Require("Shared/Validation/PresetCompatibility.lua")
local ResourceHelper = Ext.Require("Shared/Helpers/ResourceHelper.lua")

local ViewModeHelpers = {}

-- Configuration
local ATTRIBUTE_KEYS = {
    { key = "Visuals",   locaKey = "UI_HEADER_VISUALS" },
    { key = "EyeColor",  locaKey = "RESOURCE_EYE_COLOUR" },
    { key = "HairColor", locaKey = "RESOURCE_HAIR_COLOUR" },
    { key = "SkinColor", locaKey = "RESOURCE_SKIN_COLOR" },
    { key = "Elements",  locaKey = "RESOURCE_MATERIAL_OVERRIDE" },
}

-- Format mod resources with filtering
local function _FormatModResources(resources)
    if not resources then return "" end

    local parts = {}
    for _, resource in ipairs(resources) do
        table.insert(parts, string.format("%s (%s)", resource.DisplayName, resource.SlotName))
    end

    return table.concat(parts, "\n\t")
end

-- Format single mod line
local function _FormatModLine(mod)
    local resourcesText = _FormatModResources(mod.Resources)
    if resourcesText == "" then return nil end
    resourcesText = ResourceHelper:CleanDisplayName(resourcesText)

    local prefix = mod.IsLoaded and "" or Loca.Get(Loca.Keys.UI_MISSING_MOD) .. " "
    return string.format("%s%s: %s", prefix, mod.Name, resourcesText)
end

-- Collect all warnings
local function _CollectWarnings(compatibilityInfo)
    local allWarnings = {}

    for _, mod in ipairs(compatibilityInfo.AllMods) do
        if not mod.IsLoaded then
            table.insert(allWarnings, Loca.Format(
                Loca.Keys.UI_WARN_MISSING_MOD,
                mod.Name,
                mod.UUID
            ))
        end
    end

    for _, warning in ipairs(compatibilityInfo.Warnings) do
        table.insert(allWarnings, warning)
    end

    return allWarnings
end

-- Show apply confirmation
local function _ShowApplyConfirmation(group, record, warnings)
    if #warnings == 0 then
        State:ApplyPreset(record)
        return
    end

    local msg = Loca.Format(
        Loca.Keys.UI_MSG_COMPATIBILITY_WARNING,
        table.concat(warnings, "\n- ")
    )

    MessageBox:Create(
        Loca.Get(Loca.Keys.UI_TITLE_COMPATIBILITY_WARNING),
        msg,
        MessageBoxMode.YesNo
    )
        :SetYesCallback(function() State:ApplyPreset(record) end)
        :Show(group)
end

-- Create disabled apply button for CC
local function _CreateDisabledApplyButton(group)
    local ccWarning = group:AddText(Loca.Get(Loca.Keys.UI_WARN_CC_RESTRICTION))
    ccWarning:SetColor("Text", UIColors.COLOR_RED)

    local btnApply = group:AddButton(Loca.Get(Loca.Keys.UI_BUTTON_CANNOT_APPLY))
    if StyleHelpers and StyleHelpers.DisableButton then
        StyleHelpers.DisableButton(btnApply)
    else
        btnApply.Disabled = true
    end

    return btnApply
end

-- Create active apply button
local function _CreateApplyButton(group, record, compatibilityInfo)
    local btnApply = group:AddButton(Loca.Get(Loca.Keys.UI_BUTTON_APPLY))
    btnApply:SetColor("Button", UIColors.COLOR_GREEN)
    btnApply.OnClick = function()
        local warnings = _CollectWarnings(compatibilityInfo)
        _ShowApplyConfirmation(group, record, warnings)
    end
    return btnApply
end

-- Render inspected value
local function _RenderInspectedValue(attrChild, label, inspected)
    if type(inspected) == "table" then
        if #inspected > 0 then
            attrChild:AddText(label .. ":")
            for _, line in ipairs(inspected) do
                attrChild:AddText("  - " .. line)
            end
        end
    else
        if inspected ~= "" and not string.find(inspected, "Unknown") then
            attrChild:AddText(string.format("%s: %s", label, inspected))
        end
    end
end

function ViewModeHelpers.GetCompatibilityInfo(preset)
    local warnings = {}
    local allMods = {}
    local missingMods = {}
    local player = _C()

    if PresetCompatibility and player then
        warnings = PresetCompatibility.Check(preset, player)
        allMods = Preset.GetMods(preset)
        missingMods = PresetCompatibility.CheckMods(preset)
    end

    return {
        Warnings = warnings,
        AllMods = allMods,
        MissingMods = missingMods,
    }
end

function ViewModeHelpers.RenderHeader(group, record)
    if not record or not record.preset then
        return CPFWarn(0, "ViewModeHelpers.RenderHeader: record or record.preset is nil")
    end

    local preset = record.preset
    group:AddText(Loca.Format(Loca.Keys.UI_LABEL_NAME_VALUE, preset.Name or "Unknown"))
    if record.indexData.source and string.lower(record.indexData.source) ~= 'user' then
        group:AddText(Loca.Format(Loca.Keys.UI_LABEL_SOURCE_VALUE, record.indexData.source))
    end
    group:AddText(Loca.Format(Loca.Keys.UI_LABEL_AUTHOR_VALUE, preset.Author or "Unknown"))
    local versionText = group:AddText(Loca.Format(Loca.Keys.UI_LABEL_VERSION_VALUE, preset.Version or "Unknown"))
    versionText:SetColor("Text", UIColors.COLOR_GRAY)


    local IDText = group:AddText(Loca.Format(Loca.Keys.UI_LABEL_ID_VALUE, preset._id or "Unknown"))
    IDText:SetColor("Text", UIColors.COLOR_GRAY)

    group:AddSeparator()
end

function ViewModeHelpers.RenderActions(group, record, compatibilityInfo)
    -- Disable button in CC
    local isInCC = CCA.IsInCC() and not Ext.Debug.IsDeveloperMode()
    local btnApply = isInCC
        and _CreateDisabledApplyButton(group)
        or _CreateApplyButton(group, record, compatibilityInfo)

    btnApply.SameLine = false

    local buttonSpacing = group:AddSpacing()
    buttonSpacing.SameLine = true

    -- Check if preset is hidden
    local isHidden = record.indexData and record.indexData.hidden

    if isHidden then
        -- Show Unhide button for hidden presets
        local btnUnhide = group:AddButton(Loca.Get(Loca.Keys.UI_BUTTON_UNHIDE_PRESET))
        -- btnUnhide:SetColor("Button", UIColors.COLOR_GREEN)
        btnUnhide.OnClick = function()
            State:UnhidePreset(record)
        end
        btnUnhide.SameLine = true
    else
        -- Show Hide button for visible presets
        local btnHide = group:AddButton(Loca.Get(Loca.Keys.UI_BUTTON_HIDE_PRESET))
        btnHide:SetColor("Button", UIColors.COLOR_RED)
        btnHide.OnClick = function()
            State:HidePreset(record)
        end
        btnHide.SameLine = true
    end

    group:AddSeparator()
end

function ViewModeHelpers.RenderModList(group, compatibilityInfo)
    local allMods = compatibilityInfo.AllMods
    if #allMods == 0 then return end

    local modLines = {}
    for _, mod in ipairs(allMods) do
        local line = _FormatModLine(mod)
        if line then
            table.insert(modLines, line)
        end
    end

    if #modLines == 0 then return end

    local modsText = group:AddBulletText(Loca.Format(
        Loca.Keys.UI_HEADER_MODS_USED,
        table.concat(modLines, "\n")
    ))
    modsText.TextWrapPos = -1

    if #compatibilityInfo.MissingMods > 0 then
        modsText:SetColor("Text", UIColors.COLOR_RED)
    end
end

function ViewModeHelpers.RenderWarnings(group, compatibilityInfo)
    local warnings = compatibilityInfo.Warnings
    if #warnings == 0 then return end

    local compatibilityWarning = group:AddBulletText(Loca.Format(
        Loca.Keys.UI_HEADER_COMPATIBILITY_WARNINGS,
        table.concat(warnings, "\n")
    ))
    compatibilityWarning:SetColor("Text", UIColors.COLOR_ORANGE)
    compatibilityWarning.TextWrapPos = -1
end

function ViewModeHelpers.RenderAttributes(group, preset)
    local attrChild = group:AddChildWindow("AttributesView")
    local appearanceData = preset.Data and preset.Data.CCAppearance

    if not appearanceData then
        attrChild:AddText(Loca.Get(Loca.Keys.UI_MSG_NO_DATA_AVAILABLE))
        return
    end

    for _, config in ipairs(ATTRIBUTE_KEYS) do
        local value = appearanceData[config.key]
        if value then
            local inspected = PresetInspector:Inspect(config.key, value)
            if inspected then
                local label = Loca.Get(Loca.Keys[config.locaKey])
                if label == "[NO LOCA " .. tostring(Loca.Keys[config.locaKey]) .. "]" then
                    label = config.key
                end
                _RenderInspectedValue(attrChild, label, inspected)
            end
        end
    end
end

return ViewModeHelpers
