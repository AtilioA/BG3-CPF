local State = Ext.Require("Client/UI/State.lua")
local RenderHelper = Ext.Require("Client/UI/RenderHelper.lua")

local MessageBox = Ext.Require("Client/UI/Components/MessageBox.lua")
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

            -- Compatibility Checks
            local warnings = {}
            local missingMods = {}
            local player = _C()

            if PresetCompatibility then
                if player then
                    warnings = PresetCompatibility.Check(preset, player)
                end
                missingMods = PresetCompatibility.CheckMods(preset)
            end

            if #missingMods > 0 then
                local missingModsWarning = group:AddBulletText("Missing mods:\n" .. table.concat(missingMods, "\n"))
                missingModsWarning:SetColor("Text", UIColors.COLOR_RED)
                missingModsWarning.TextWrapPos = -1
            end

            if #warnings > 0 then
                local compatibilityWarning = group:AddBulletText("Compatibility warnings:\n" .. table.concat(warnings, "\n"))
                compatibilityWarning:SetColor("Text", UIColors.COLOR_ORANGE)
                compatibilityWarning.TextWrapPos = -1
            end

            -- Actions
            local btnApply = group:AddButton("Apply preset")
            btnApply:SetColor("Button", UIColors.COLOR_GREEN)
            btnApply.OnClick = function()
                local allWarnings = {}
                for _, w in ipairs(missingMods) do table.insert(allWarnings, "Missing Mod: " .. w) end
                for _, w in ipairs(warnings) do table.insert(allWarnings, w) end

                if #allWarnings > 0 then
                    local msg = "The following issues were found:\n\n" ..
                        table.concat(allWarnings, "\n") .. "\n\nDo you want to proceed?"
                    MessageBox:Create("Compatibility Warning", msg, MessageBoxMode.YesNo)
                        :SetYesCallback(function() State:ApplyPreset(record) end)
                        :Show(group)
                else
                    State:ApplyPreset(record)
                end
            end

            btnApply.SameLine = false

            local buttonSpacing = group:AddSpacing()

            buttonSpacing.SameLine = true

            local btnDelete = group:AddButton("Hide preset")
            btnDelete:SetColor("Button", UIColors.COLOR_RED)
            btnDelete.OnClick = function()
                State:HidePreset(record)
            end

            btnDelete.SameLine = true

            group:AddSeparator()

            -- Attributes (read-only)
            local attrChild = group:AddChildWindow("AttributesView")
            local appearanceData = preset.Data and preset.Data.CCAppearance

            if appearanceData then
                -- TODO: simple recursive dumper or specific fields for now
                if appearanceData.Visuals then
                    attrChild:AddText("Visuals:")
                    for _, v in ipairs(appearanceData.Visuals) do
                        attrChild:AddText("  - " .. tostring(v))
                    end
                end
            else
                attrChild:AddText("No data available.")
            end
        end)
end

return ViewMode


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
-- for _, v in ipairs(preset.Data.Visuals) do
-- Ext.StaticData.Get("bc372dfb-3a0a-4fc4-a23d-068a12699d78", "CharacterCreationSharedVisual"
-- local visualRecordDisplayName = Ext.StaticData.Get(v, "CharacterCreationAppearanceVisual")
-- attrChild:AddText("  - " .. tostring(visualRecordDisplayName.DisplayName:Get()))
