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
                    group:AddText(Loca.Get(Loca.Keys.UI_MSG_NO_PRESETS))
                else
                    group:AddText(Loca.Get(Loca.Keys.UI_MSG_SELECT_PRESET))
                end
                return
            end

            local preset = record.preset

            -- Header
            group:AddText(Loca.Format(Loca.Keys.UI_LABEL_NAME_VALUE, preset.Name or "Unknown"))
            group:AddText(Loca.Format(Loca.Keys.UI_LABEL_AUTHOR_VALUE, preset.Author or "Unknown"))
            group:AddText(Loca.Format(Loca.Keys.UI_LABEL_VERSION_VALUE, preset.Version or "Unknown"))
            local IDText = group:AddText(Loca.Format(Loca.Keys.UI_LABEL_ID_VALUE, preset._id or "Unknown"))
            IDText:SetColor("Text", UIColors.COLOR_GRAY)

            -- Compatibility Checks
            local warnings = {}
            local allMods = {}
            local missingMods = {}
            local player = _C()

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
                local modsText = group:AddBulletText(Loca.Format(Loca.Keys.UI_HEADER_MODS_USED,
                    table.concat(modLines, "\n")))
                modsText.TextWrapPos = -1

                -- Apply warning color only if there are missing mods
                if #missingMods > 0 then
                    modsText:SetColor("Text", UIColors.COLOR_RED)
                end
            end

            if #warnings > 0 then
                local compatibilityWarning = group:AddBulletText(Loca.Format(Loca.Keys.UI_HEADER_COMPATIBILITY_WARNINGS,
                    table.concat(warnings, "\n")))
                compatibilityWarning:SetColor("Text", UIColors.COLOR_ORANGE)
                compatibilityWarning.TextWrapPos = -1
            end

            group:AddSeparator()

            -- Actions
            -- Disable button in CC
            local btnApply
            if CCA.IsInCC() and not Ext.Debug.IsDeveloperMode() then
                local ccWarning = group:AddText(Loca.Get(Loca.Keys.UI_WARN_CC_RESTRICTION))
                ccWarning:SetColor("Text", UIColors.COLOR_RED)
                btnApply = group:AddButton(Loca.Get(Loca.Keys.UI_BUTTON_CANNOT_APPLY))
                StyleHelpers.DisableButton(btnApply)
                btnApply.Disabled = true
            else
                btnApply = group:AddButton(Loca.Get(Loca.Keys.UI_BUTTON_APPLY))
                btnApply:SetColor("Button", UIColors.COLOR_GREEN)
                btnApply.OnClick = function()
                    local allWarnings = {}
                    for _, mod in ipairs(allMods) do
                        if not mod.IsLoaded then
                            table.insert(allWarnings, Loca.Format(Loca.Keys.UI_WARN_MISSING_MOD, mod.Name, mod.UUID))
                        end
                    end
                    for _, w in ipairs(warnings) do table.insert(allWarnings, w) end

                    if #allWarnings > 0 then
                        local msg = Loca.Format(Loca.Keys.UI_MSG_COMPATIBILITY_WARNING, table.concat(allWarnings, "\n- "))
                        MessageBox:Create(Loca.Get(Loca.Keys.UI_TITLE_COMPATIBILITY_WARNING), msg, MessageBoxMode.YesNo)
                            :SetYesCallback(function() State:ApplyPreset(record) end)
                            :Show(group)
                    else
                        State:ApplyPreset(record)
                    end
                end
            end

            btnApply.SameLine = false

            local buttonSpacing = group:AddSpacing()

            buttonSpacing.SameLine = true

            local btnDelete = group:AddButton(Loca.Get(Loca.Keys.UI_BUTTON_HIDE_PRESET))
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
                    attrChild:AddText(Loca.Get(Loca.Keys.UI_HEADER_VISUALS))
                    for _, v in ipairs(appearanceData.Visuals) do
                        attrChild:AddText(ValueSerializer.Serialize(v, 'CharacterCreationSharedVisual'))
                    end
                end
            else
                attrChild:AddText(Loca.Get(Loca.Keys.UI_MSG_NO_DATA_AVAILABLE))
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
