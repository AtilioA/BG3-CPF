local State = Ext.Require("Client/UI/State.lua")
local RenderHelper = Ext.Require("Client/UI/RenderHelper.lua")
local ViewModeHelpers = Ext.Require("Client/UI/Modes/ViewModeHelpers.lua")
local PresetCompatibility = Ext.Require("Shared/Validation/PresetCompatibility.lua")

local ViewMode = {}

--- Analyzes all presets and determines which empty-state message to show
--- Returns a localization key based on preset state
---@return string locaKey The localization key for the appropriate message
function ViewMode:GetEmptyMessageKey()
    local presets = State.Presets:GetValue() or {}
    local totalCount = #presets

    -- No presets at all
    if totalCount == 0 then
        return Loca.Keys.UI_MSG_NO_PRESETS
    end

    -- Count hidden presets and check visible compatibility
    local hiddenCount = 0
    local visibleCount = 0
    local compatibleVisibleCount = 0
    local anyHiddenWouldBeIncompatible = false

    local player = _C()

    for _, record in ipairs(presets) do
        local isHidden = record.indexData and record.indexData.hidden

        if isHidden then
            hiddenCount = hiddenCount + 1

            -- Check if this hidden preset would be incompatible if unhidden
            if player and record.preset then
                local warnings = PresetCompatibility.Check(record.preset, player)
                if #warnings > 0 then
                    anyHiddenWouldBeIncompatible = true
                end
            end
        else
            visibleCount = visibleCount + 1

            -- Check if this visible preset is compatible
            if player and record.preset then
                local warnings = PresetCompatibility.Check(record.preset, player)
                if #warnings == 0 then
                    compatibleVisibleCount = compatibleVisibleCount + 1
                end
            else
                -- If we can't check compatibility, assume compatible
                compatibleVisibleCount = compatibleVisibleCount + 1
            end
        end
    end

    -- All presets are hidden
    if hiddenCount == totalCount then
        if anyHiddenWouldBeIncompatible then
            return Loca.Keys.UI_MSG_ALL_HIDDEN_AND_INCOMPATIBLE
        else
            return Loca.Keys.UI_MSG_ALL_PRESETS_HIDDEN
        end
    end

    -- All visible presets are incompatible
    if visibleCount > 0 and compatibleVisibleCount == 0 then
        return Loca.Keys.UI_MSG_ALL_PRESETS_INCOMPATIBLE
    end

    -- Default: normal selection prompt
    return Loca.Keys.UI_MSG_SELECT_PRESET
end

function ViewMode:Render(parent)
    -- Create reactive group that re-renders when SelectedPreset changes
    RenderHelper.CreateReactiveGroup(parent, "ViewModeContent", State.SelectedPreset,
        ---@param group ExtuiGroup
        ---@param record PresetRecord
        function(group, record)
            if not record or not record.preset then
                local messageKey = ViewMode:GetEmptyMessageKey()
                local messageText = group:AddText(Loca.Get(messageKey))
                messageText.TextWrapPos = 0
                return
            end

            local preset = record.preset

            -- Header
            ViewModeHelpers.RenderHeader(group, record)

            -- Compatibility checks
            local compatibilityInfo = ViewModeHelpers.GetCompatibilityInfo(preset)

            -- Actions
            ViewModeHelpers.RenderActions(group, record, compatibilityInfo)

            -- Display all mods used by the preset
            ViewModeHelpers.RenderModList(group, compatibilityInfo)

            -- Warnings
            ViewModeHelpers.RenderWarnings(group, compatibilityInfo)

            -- Attributes (read-only)
            ViewModeHelpers.RenderAttributes(group, preset)
        end)
end

return ViewMode
