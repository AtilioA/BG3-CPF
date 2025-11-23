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
    local btnRefresh = parent:AddButton("Refresh")
    btnRefresh.OnClick = function() State:RefreshPresets() end

    btnRefresh.SameLine = true
    local btnImport = parent:AddButton("Import")
    btnImport.OnClick = function() State:SetMode("IMPORT") end

    btnImport.SameLine = true
    local btnCreate = parent:AddButton("Create from Self")
    btnCreate.OnClick = function()
        -- TODO: Get actual player name
        State:CaptureCharacterData("Self") end

    btnCreate.SameLine = true

    parent:AddSeparator()

    -- Preset List - reactive group that updates when Presets changes
    local listChild = parent:AddChildWindow("PresetList")

    RenderHelper.CreateReactiveGroup(listChild, "PresetsList", State.Presets, function(group, presets)
        for i, preset in ipairs(presets) do
            local label = preset.Name or ("Preset " .. i)
            local item = group:AddButton(label)
            item.OnClick = function()
                State:SelectPreset(preset)
            end
        end
    end)
end

function Window:RenderCPFWindow()
    local window = Ext.IMGUI.NewWindow("Character Preset Framework")

    -- Status bar (at the top)
    if not self.StatusText then
        self.StatusText = window:AddText("")
    end
    self.StatusText.Label = State.StatusMessage:GetValue() or ""
    State.StatusMessage:Subscribe(function(msg)
        self.StatusText.Label = msg or ""
    end)

    window:AddSeparator()

    -- Main Layout Table
    local table = window:AddTable("MainLayout", 2)
    table.Borders = true
    table.Resizable = true
    table:AddColumn("Sidebar")
    table:AddColumn("Content")

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
