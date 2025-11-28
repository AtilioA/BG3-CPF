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
        local btnRefresh = parent:AddButton("Refresh")
        btnRefresh.OnClick = function() State:RefreshPresets() end
        btnRefresh.SameLine = true
    end

    local btnImport = parent:AddButton("Import")
    btnImport.OnClick = function() State:SetMode("IMPORT") end

    btnImport.SameLine = true

    local vSeparator = parent:AddText("|")
    vSeparator.SameLine = true

    local btnCreate = parent:AddButton("Preset creation")

    btnCreate.OnClick = function()
        -- TODO: Get actual character name
        State:CaptureCharacterData()
    end

    btnCreate.SameLine = true

    parent:AddSeparator()

    -- Preset List - reactive group that updates when Presets changes
    local listChild = parent:AddChildWindow("PresetList")

    local table = nil
    RenderHelper.CreateReactiveGroup(listChild, "PresetsList", State.Presets,
        ---@param group ExtuiGroup
        ---@param records PresetRecord[]
        function(group, records)
            table = group:AddTable("PresetsTable", 1)

            local _colName = table:AddColumn("Name", "WidthStretch")
            -- Add header row
            local headerRow = table:AddRow()
            headerRow:AddCell():AddSeparatorText("Preset list")
            -- Add preset rows
            for i, record in ipairs(records) do
                local row = table:AddRow()

                local nameCell = row:AddCell()
                local label = (record.preset.Name .. "##" .. record.preset._id) or ("Preset " .. i)

                local item = nameCell:AddButton(label)
                item.Size = { -1, 50 }
                item.OnClick = function()
                    State:SelectPreset(record)
                end
            end

            local activeProfileButton = nil
            -- TODO: Refactor UI styling in general post release, this is gross
            State.SelectedPreset:Subscribe(function(selected)
                if not selected then return end
                -- Iterate children of table; if button, check label, set active/inactive
                -- REFACTOR: this is brittle smh
                for _, child in ipairs(table.Children) do
                    local cellChild = child.Children[1].Children[1]
                    if Ext.Types.IsA(cellChild, "extui::Button") then
                        if cellChild.Label == selected.preset.Name .. "##" .. selected.preset._id then
                            activeProfileButton = cellChild
                            cellChild:SetColor("Button", Mods.BG3MCM.UIStyle.Colors.ButtonActive)
                            -- cellChild.Label = "> " .. buttonName .. "##" .. buttonHash
                        else
                            -- Remove '> ' if existent
                            -- cellChild.Label = cellChild.Label:gsub("^> ", "")
                            cellChild:SetColor("Button", Mods.BG3MCM.UIStyle.Colors.Button)
                        end
                    end
                end
            end)

            State.ViewMode:Subscribe(function(mode)
                btnCreate.Label = (mode == "CREATE" and "> " or "") .. "Preset creation"
                btnImport.Label = (mode == "IMPORT" and "> " or "") .. "Import"

                -- Dumb button might not exist anymore
                pcall(function ()
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
            group:AddText("Unknown mode: " .. tostring(currentMode))
        end
    end)
end

return Window
