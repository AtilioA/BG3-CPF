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
            local IDText = group:AddText("ID: " .. (preset._id or "Unknown"))
            IDText:SetColor("Text", UIColors.COLOR_GRAY)

            -- Compatibility Checks
            local warnings = {}
            local allMods = {}
            local missingMods = {}
            local player = _C()
            -- TODO: refactor
            -- if player and player.Level and player.Level.LevelName == ""

            if PresetCompatibility then
                if player then
                    warnings = PresetCompatibility.Check(preset, player)
                end
                allMods = Preset.GetMods(preset)
                missingMods = PresetCompatibility.CheckMods(preset)
            end

            -- Display all mods used by the preset
            if #allMods > 0 then
                local modLines = {}
                for _, mod in ipairs(allMods) do
                    local modResources = ""
                    if mod.Resources then
                        for _, resource in ipairs(mod.Resources) do
                            modResources = table.concat(
                                { modResources, string.format("%s (%s)", resource.DisplayName, resource.SlotName) },
                                "\n\t")
                        end
                    end
                    if mod.IsLoaded == true then
                        table.insert(modLines, string.format("%s: %s", mod.Name, modResources))
                    else
                        table.insert(modLines, string.format("(MISSING) %s: %s", mod.Name, modResources))
                    end
                end

                group:AddSeparator()
                local modsText = group:AddBulletText("Mods used by this preset:\n" .. table.concat(modLines, "\n"))
                modsText.TextWrapPos = -1

                -- Apply warning color only if there are missing mods
                if #missingMods > 0 then
                    modsText:SetColor("Text", UIColors.COLOR_RED)
                end
            end

            if #warnings > 0 then
                local compatibilityWarning = group:AddBulletText("Compatibility warnings:\n" ..
                    table.concat(warnings, "\n"))
                compatibilityWarning:SetColor("Text", UIColors.COLOR_ORANGE)
                compatibilityWarning.TextWrapPos = -1
            end

            group:AddSeparator()

            -- Actions
            local btnApply = group:AddButton("Apply preset")
            btnApply:SetColor("Button", UIColors.COLOR_GREEN)
            btnApply.OnClick = function()
                local allWarnings = {}
                for _, mod in ipairs(allMods) do
                    if not mod.IsLoaded then
                        table.insert(allWarnings, string.format("Missing mod: %s (%s)", mod.Name, mod.UUID))
                    end
                end
                for _, w in ipairs(warnings) do table.insert(allWarnings, w) end

                if #allWarnings > 0 then
                    local msg = "The following issues were found:\n\n" ..
                        table.concat(allWarnings, "\n") ..
                        "\n\nThis will cause issues with your character's appearance. Find a compatible preset or change your character with AEE instead.\nAre you sure you want to proceed?"
                    MessageBox:Create("Compatibility warning", msg, MessageBoxMode.YesNo)
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
                -- TODO: come up with some logic to deal with this. some are shared visuals, some are appearance visuals. Index matters but not sure how to handle it
                if appearanceData.Visuals then
                    attrChild:AddText("Visuals:")
                    for _, v in ipairs(appearanceData.Visuals) do
                        attrChild:AddText(ValueSerializer.Serialize(v, 'CharacterCreationSharedVisual'))
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
