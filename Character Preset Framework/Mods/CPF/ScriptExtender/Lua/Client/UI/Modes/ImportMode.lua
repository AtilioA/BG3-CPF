local State = Ext.Require("Client/UI/State.lua")
local RenderHelper = Ext.Require("Client/UI/RenderHelper.lua")

local ImportMode = {}

function ImportMode:Render(parent)
    -- Wrap entire content in a managed group
    RenderHelper.CreateManagedGroup(parent, "ImportModeContent", function(group)
        if (not Ext.Debug.IsDeveloperMode()) or (Ext.Utils.Version() <= 30) then
            group:AddText("You need SE v30 or Devel to use this feature.")
            CPFWarn(1, "Import feature is still not available!")
            return false
        end
        group:AddText("WIP: paste a preset JSON below:")

        local input = group:AddInputText("")
        input.Multiline = true
        input.SizeHint = { 450, 400 }
        input.Text = State.ImportBuffer
        input.OnChange = function() State.ImportBuffer = input.Text end

        local btnImport = group:AddButton("Import")
        btnImport.Disabled = true
        btnImport.OnClick = function()
            State:ImportFromBuffer()
        end

        btnImport.SameLine = false

        local btnCancel = group:AddButton("Cancel")
        btnCancel.OnClick = function()
            State:SetMode("VIEW")
        end

        btnCancel.SameLine = true
    end)
end

return ImportMode
