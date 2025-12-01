local State = Ext.Require("Client/UI/State.lua")
local RenderHelper = Ext.Require("Client/UI/RenderHelper.lua")

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
            presetsTable = group:AddTable("PresetsTable", 1)

            local _colName = presetsTable:AddColumn("Name", "WidthStretch")
            -- Add header row
            local headerRow = presetsTable:AddRow()
            headerRow:AddCell():AddSeparatorText(Loca.Get(Loca.Keys.UI_HEADER_PRESET_LIST))

            -- Sort and separate presets
            local compatible = {}
            local incompatible = {}
            local character = nil
            if State.TargetCharacterUUID then
                character = Ext.Entity.Get(State.TargetCharacterUUID)
            end
            if not character then character = _C() end

            for _, record in ipairs(records) do
                local isCompatible = true
                if PresetCompatibility and character and record.preset then
                    local warnings = PresetCompatibility.Check(record.preset, character)
                    if #warnings > 0 then isCompatible = false end
                end

                if isCompatible then
                    table.insert(compatible, record)
                else
                    table.insert(incompatible, record)
                end
            end

            local sortFunc = function(a, b)
                local nameA = (a.preset and a.preset.Name) or ""
                local nameB = (b.preset and b.preset.Name) or ""
                return nameA < nameB
            end
            table.sort(compatible, sortFunc)
            table.sort(incompatible, sortFunc)

            local function addPresetRow(record, isCompatible)
                local row = presetsTable:AddRow()
                local nameCell = row:AddCell()
                local label = (record.preset.Name .. "##" .. record.preset._id) or ("Preset " .. record.preset._id)

                local item = nameCell:AddButton(label)
                item.Size = { -1, 50 }
                item.UserData = {
                isCompatible = isCompatible,
                    record = record
                }
                if not isCompatible then
                    item:SetColor("Button", UIColors.BUTTON_DISABLED)
                    item:SetColor("Text", Mods.BG3MCM.UIStyle.Colors.TextDisabled)
                end
                item.OnClick = function()
                    State:SelectPreset(record)
                end
            end

            for _, record in ipairs(compatible) do
                addPresetRow(record, true)
            end

            if #incompatible > 0 then
                local sepRow = presetsTable:AddRow()
                sepRow:AddCell():AddSeparatorText("Incompatible presets")

                for _, record in ipairs(incompatible) do
                    addPresetRow(record, false)
                end
            end

            local activeProfileButton = nil
            -- TODO: Refactor UI styling in general post release, this is gross
            State.SelectedPreset:Subscribe(function(selected)
                if not selected then return end
                -- Iterate children of table; if button, check label, set active/inactive
                -- REFACTOR: this is brittle smh
                for _, child in ipairs(presetsTable.Children) do
                    local cellChild = child.Children[1].Children[1]
                    if Ext.Types.IsA(cellChild, "extui::Button") then
                        if cellChild.Label == selected.preset.Name .. "##" .. selected.preset._id then
                            activeProfileButton = cellChild
                            cellChild:SetColor("Button", Mods.BG3MCM.UIStyle.Colors.ButtonActive)
                            -- cellChild.Label = "> " .. buttonName .. "##" .. buttonHash
                        else
                            if cellChild.UserData.isCompatible then
                                cellChild:SetColor("Button", Mods.BG3MCM.UIStyle.Colors.Button)
                            else
                                cellChild:SetColor("Button", UIColors.BUTTON_DISABLED)
                            end
                            -- Remove '> ' if existent
                            -- cellChild.Label = cellChild.Label:gsub("^> ", "")
                        end
                    end
                end
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
        local modeRenderer = Modes[currentMode]

        if modeRenderer and modeRenderer.Render then
            modeRenderer:Render(group)
        else
            group:AddText(Loca.Format(Loca.Keys.UI_ERROR_UNKNOWN_MODE, currentMode))
        end
    end)
end

return Window
