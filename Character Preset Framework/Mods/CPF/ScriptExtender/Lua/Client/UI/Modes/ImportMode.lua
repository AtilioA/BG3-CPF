local State = Ext.Require("Client/UI/State.lua")
local RenderHelper = Ext.Require("Client/UI/RenderHelper.lua")

local ImportMode = {}

function ImportMode:Render(parent)
    -- Wrap entire content in a managed group
    RenderHelper.CreateManagedGroup(parent, "ImportModeContent", function(group)
        group:AddText("WIP: paste a preset JSON below:\nNOTE: this is pending a new SE fix slated for v30?")

        local input = group:AddInputText("")
        input.Multiline = true
        input.SizeHint = {450, 400}
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
