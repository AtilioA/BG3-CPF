local State = Ext.Require("Client/UI/State.lua")
local RenderHelper = Ext.Require("Client/UI/RenderHelper.lua")
local COLOR_RED = { 1.0, 0.2, 0.2, 1.0 }

local ViewMode = {}

function ViewMode:Render(parent)
    -- Create reactive group that re-renders when SelectedPreset changes
    RenderHelper.CreateReactiveGroup(parent, "ViewModeContent", State.SelectedPreset,
        ---@param group ExtuiGroup
        ---@param record PresetRecord
        function(group, record)
            if not record or not record.preset then
                if State.Presets:GetValue() and #State.Presets:GetValue() == 0 then
                    group:AddText("No presets available.\nStart by importing or creating a new preset.")
                else
                    group:AddText("Click a preset on the left to view details.")
                end
                return
            end

            local preset = record.preset

            -- Header
            group:AddText("Name: " .. (preset.Name or "Unknown"))
            group:AddText("Author: " .. (preset.Author or "Unknown"))
            group:AddText("Version: " .. (preset.Version or "Unknown"))

            group:AddSeparator()

            -- Actions
            local btnApply = group:AddButton("Apply")
            btnApply.OnClick = function()
                State:ApplyPreset(record)
            end

            btnApply.SameLine = true

            local btnDelete = group:AddButton("Delete")
            btnDelete:SetColor("Button", COLOR_RED)
            btnDelete.OnClick = function()
                State:HidePreset(record)
            end

            group:AddSeparator()

            -- Attributes (read-only)
            local attrChild = group:AddChildWindow("AttributesView")
            if preset.Data then
                -- TODO: simple recursive dumper or specific fields for now
                if preset.Data.Visuals then
                    attrChild:AddText("Visuals:")
                    -- TODO: fetch display names
                    -- CharacterCreationAccessorySet = 18,
                    -- CharacterCreationAppearanceMaterial = 19,
                    -- CharacterCreationAppearanceVisual = 20,
                    -- CharacterCreationEquipmentIcons = 21,
                    -- CharacterCreationEyeColor = 22,
                    -- CharacterCreationIconSettings = 23,
                    -- CharacterCreationHairColor = 24,
                    -- CharacterCreationMaterialOverride = 25,
                    -- CharacterCreationPassiveAppearance = 26,
                    -- CharacterCreationPreset = 27,
                    -- CharacterCreationSharedVisual = 28,
                    -- CharacterCreationSkinColor = 29,
                    for _, v in ipairs(preset.Data.Visuals) do
                        -- Ext.StaticData.Get("bc372dfb-3a0a-4fc4-a23d-068a12699d78", "CharacterCreationSharedVisual"
                        -- local visualRecordDisplayName = Ext.StaticData.Get(v, "CharacterCreationAppearanceVisual")
                        -- attrChild:AddText("  - " .. tostring(visualRecordDisplayName.DisplayName:Get()))
                        attrChild:AddText("  - " .. tostring(v))
                    end
                end
                -- if preset.Data.SkinColor then
                --     attrChild:AddText("Colors:")
                --     for k, v in pairs(preset.Data.Colors) do
                --         attrChild:AddText("  " .. k .. ": " .. tostring(v))
                --     end
                -- end
            else
                attrChild:AddText("No data available.")
            end
        end)
end

return ViewMode
