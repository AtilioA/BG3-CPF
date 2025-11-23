local State = Ext.Require("Client/UI/State.lua")
local RenderHelper = Ext.Require("Client/UI/RenderHelper.lua")

local ImportMode = {}

function ImportMode:Render(parent)
    -- Wrap entire content in a managed group
    RenderHelper.CreateManagedGroup(parent, "ImportModeContent", function(group)
        group:AddText("Import preset JSON")

        local input = group:AddInputText("Paste JSON")
        input.Multiline = true
        input.SizeHint = {0, 300}
        input.Text = State.ImportBuffer
        input.OnChange = function() State.ImportBuffer = input.Text end

        group:AddSeparator()

        local btnImport = group:AddButton("Import")
        btnImport.OnClick = function()
            State:ImportFromBuffer()
        end

        btnImport.SameLine = true

        local btnCancel = group:AddButton("Cancel")
        btnCancel.OnClick = function()
            State:SetMode("VIEW")
        end
    end)
end

return ImportMode
