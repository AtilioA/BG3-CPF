local State = Ext.Require("Client/UI/State.lua")
local RenderHelper = Ext.Require("Client/UI/RenderHelper.lua")
local ViewModeHelpers = Ext.Require("Client/UI/Modes/ViewModeHelpers.lua")

local ViewMode = {}

function ViewMode:Render(parent)
    -- Create reactive group that re-renders when SelectedPreset changes
    RenderHelper.CreateReactiveGroup(parent, "ViewModeContent", State.SelectedPreset,
        ---@param group ExtuiGroup
        ---@param record PresetRecord
        function(group, record)
            if not record or not record.preset then
                if State.Presets:GetValue() and #State.Presets:GetValue() == 0 then
                    group:AddText(Loca.Get(Loca.Keys.UI_MSG_NO_PRESETS))
                else
                    group:AddText(Loca.Get(Loca.Keys.UI_MSG_SELECT_PRESET))
                end
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
