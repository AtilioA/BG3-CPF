local State = Ext.Require("Client/UI/State.lua")
local RenderHelper = Ext.Require("Client/UI/RenderHelper.lua")
local WindowHelpers = Ext.Require("Client/UI/WindowHelpers.lua")

-- Mode Registry
local Modes = {
    VIEW = Ext.Require("Client/UI/Modes/ViewMode.lua"),
    CREATE = Ext.Require("Client/UI/Modes/CreateMode.lua"),
    IMPORT = Ext.Require("Client/UI/Modes/ImportMode.lua")
}

local Window = {
    ID = "CPF_Preset_Manager"
}

function Window:DrawSidebar(parent)
    -- Toolbar
    if tonumber(MCM.Get("debug_level")) >= 3 then
        local btnRefresh = parent:AddButton(Loca.Get(Loca.Keys.UI_BUTTON_REFRESH))
        btnRefresh.OnClick = function() State:RefreshPresets() end
        btnRefresh.SameLine = true
    end

    local btnImport = parent:AddButton(Loca.Get(Loca.Keys.UI_BUTTON_IMPORT))
    btnImport.OnClick = function() State:SetMode("IMPORT") end

    btnImport.SameLine = true

    local vSeparator = parent:AddText("|")
    vSeparator.SameLine = true

    local btnCreate = parent:AddButton(Loca.Get(Loca.Keys.UI_BUTTON_PRESET_CREATION))

    btnCreate.OnClick = function()
        -- TODO: Get actual character name
        State:CaptureCharacterData()
    end

    btnCreate.SameLine = true

    parent:AddSeparator()

    -- Preset List - reactive group that updates when Presets changes
    local listChild = parent:AddChildWindow("PresetList")

    local presetsTable = nil
    RenderHelper.CreateReactiveGroup(listChild, "PresetsList", State.Presets,
        ---@param group ExtuiGroup
        ---@param records PresetRecord[]
        function(group, records)
            local presetsCW = group:AddChildWindow("PresetsCW")
            presetsTable = presetsCW:AddTable("PresetsTable", 1)

            local _colName = presetsTable:AddColumn("Name", "WidthStretch")
            -- Add header row
            local headerRow = presetsTable:AddRow()
            headerRow:AddCell():AddSeparatorText(Loca.Get(Loca.Keys.UI_HEADER_PRESET_LIST))

            -- Sort and separate presets
            local compatible, incompatible, hidden = WindowHelpers.GetSortedPresets(records)

            if #compatible == 0 then
                local sepRow = presetsTable:AddRow()
                sepRow:AddCell():AddText(Loca.Get(Loca.Keys.UI_TEXT_NO_COMPATIBLE_PRESETS))
            end

            for _, record in ipairs(compatible) do
                WindowHelpers.AddPresetRow(presetsTable, record, true)
            end

            if #incompatible > 0 then
                local sepRow = presetsTable:AddRow()
                local rowCell = sepRow:AddCell()
                local incompatibleSepText = rowCell:AddSeparatorText(Loca.Get(Loca.Keys.UI_TEXT_INCOMPATIBLE_PRESETS))
                local incompatibleSectionTooltip = incompatibleSepText:Tooltip()
                incompatibleSectionTooltip:AddText(
                    Loca.Get(Loca.Keys.UI_TEXT_INCOMPATIBLE_PRESETS_TOOLTIP))

                for _, record in ipairs(incompatible) do
                    WindowHelpers.AddPresetRow(presetsTable, record, false)
                end
            end

            if #hidden > 0 then
                local hiddenRow = presetsTable:AddRow()
                local hiddenCell = hiddenRow:AddCell()
                hiddenCell:AddDummy(10, 10)
                hiddenCell:AddSeparator()
                hiddenCell:AddDummy(10, 10)
                local hiddenHeader = hiddenCell:AddCollapsingHeader(Loca.Get(Loca.Keys.UI_TEXT_HIDDEN_PRESETS))
                local hiddenPresetsTable = hiddenHeader:AddTable("HiddenPresetsTable", 1)
                hiddenHeader:SetColor("Header", UIColors.BUTTON_DISABLED)
                hiddenHeader:SetColor("Text", Mods.BG3MCM.UIStyle.Colors.TextDisabled)
                hiddenHeader.DefaultOpen = false

                for _, record in ipairs(hidden) do
                    WindowHelpers.AddPresetRow(hiddenPresetsTable, record, false)
                end
            end

            local activeProfileButton = nil
            -- TODO: Refactor UI styling in general post release, this is gross
            State.SelectedPreset:Subscribe(function(selected)
                activeProfileButton = WindowHelpers.UpdateActivePresetButton(presetsTable, selected)
            end)

            State.ViewMode:Subscribe(function(mode)
                btnCreate.Label = (mode == "CREATE" and "> " or "") .. Loca.Get(Loca.Keys.UI_BUTTON_PRESET_CREATION)
                btnImport.Label = (mode == "IMPORT" and "> " or "") .. Loca.Get(Loca.Keys.UI_BUTTON_IMPORT)

                -- Dumb button might not exist anymore
                pcall(function()
                    if mode ~= "VIEW" and activeProfileButton then
                        activeProfileButton:SetColor("Button", Mods.BG3MCM.UIStyle.Colors.Button)
                    end
                end)
            end)
        end)
end

function Window:RenderCPF(window)
    -- local window = Ext.IMGUI.NewWindow("Character Preset Framework")

    -- Status bar (at the top)
    -- TODO: Add some distinctive color to the status bar?
    if not self.StatusText then
        self.StatusText = window:AddText("")
    end
    self.StatusText.Label = State.StatusMessage:GetValue() or ""
    State.StatusMessage:Subscribe(function(msg)
        self.StatusText.Label = msg or ""
    end)

    -- Main Layout Table
    local table = window:AddTable("MainLayout", 2)
    table.Borders = true
    local sidebar = table:AddColumn("Sidebar", "WidthFixed", 400)
    local content = table:AddColumn("Content", "WidthStretch")

    local row = table:AddRow()

    -- Left Column
    local cellLeft = row:AddCell()
    self:DrawSidebar(cellLeft)

    -- Right Column - Use reactive group that updates when ViewMode changes
    local cellRight = row:AddCell()

    RenderHelper.CreateReactiveGroup(cellRight, "ModeContent", State.ViewMode, function(group, currentMode)
        -- local modeCW = group:AddChildWindow("ModeCW")
        local modeRenderer = Modes[currentMode]

        if modeRenderer and modeRenderer.Render then
            modeRenderer:Render(group)
        else
            group:AddText(Loca.Format(Loca.Keys.UI_ERROR_UNKNOWN_MODE, currentMode))
        end
    end)
end

return Window
