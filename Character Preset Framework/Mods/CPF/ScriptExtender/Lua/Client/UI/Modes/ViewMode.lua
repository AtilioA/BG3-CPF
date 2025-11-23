local State = Ext.Require("Client/UI/State.lua")
local RenderHelper = Ext.Require("Client/UI/RenderHelper.lua")
local COLOR_RED = {1.0, 0.2, 0.2, 1.0}

local ViewMode = {}

function ViewMode:Render(parent)
    -- Create reactive group that re-renders when SelectedPreset changes
RenderHelper.CreateReactiveGroup(parent, "ViewModeContent", State.SelectedPreset, function(group, preset)
        if not preset then
            group:AddText("No preset selected.")
            return
        end

        -- Header
        group:AddText("Name: " .. (preset.Name or "Unknown"))
        group:AddText("Author: " .. (preset.Author or "Unknown"))
        group:AddText("Version: " .. (preset.Version or "Unknown"))

        group:AddSeparator()

        -- Actions
        local btnApply = group:AddButton("Apply")
        btnApply.OnClick = function()
            State:ApplyPreset(preset)
        end

        btnApply.SameLine = true

        local btnDelete = group:AddButton("Delete")
        btnDelete:SetColor("Button", COLOR_RED)
        btnDelete.OnClick = function()
            State:DeletePreset(preset)
        end

        group:AddSeparator()

        -- Attributes (read-only)
        local attrChild = group:AddChildWindow("AttributesView")
        if preset.Data then
            -- TODO: simple recursive dumper or specific fields for now
            if preset.Data.Visuals then
                attrChild:AddText("Visuals:")
                for _, v in ipairs(preset.Data.Visuals) do
                    attrChild:AddText("  - " .. tostring(v))
                end
            end
            if preset.Data.Colors then
                attrChild:AddText("Colors:")
                for k, v in pairs(preset.Data.Colors) do
                    attrChild:AddText("  " .. k .. ": " .. tostring(v))
                end
            end
        else
            attrChild:AddText("No data available.")
        end
    end)
end

return ViewMode
