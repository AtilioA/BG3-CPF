local State = Ext.Require("Client/UI/State.lua")
local RenderHelper = Ext.Require("Client/UI/RenderHelper.lua")
local ImportModeHelpers = Ext.Require("Client/UI/Modes/ImportModeHelpers.lua")

local ImportMode = {}

function ImportMode:Render(parent)
    -- Wrap entire content in a managed group
    RenderHelper.CreateManagedGroup(parent, "ImportModeContent", function(group)
        if (Ext.Utils.Version() < 30) then
            group:AddText(Loca.Get(Loca.Keys.UI_ERROR_SE_VERSION))
            CPFWarn(1, "Import feature is still not available!")
            return false
        end
        group:AddText(Loca.Get(Loca.Keys.UI_MSG_PASTE_JSON))

        local input = group:AddInputText("")
        input.Multiline = true
        input.SizeHint = { 450, 400 }
        input.Text = State.ImportBuffer:GetValue()
        input.OnChange = function()
            State.ImportBuffer:OnNext(input.Text)
        end

        -- Create reactive button group that updates when ImportBuffer changes
        RenderHelper.CreateReactiveGroup(group, "ImportButtonGroup", State.ImportBuffer,
            function(btnGroup, buffer)
                local parsedName = ImportModeHelpers.ParsePresetName(buffer)

                ImportModeHelpers.RenderImportButton(btnGroup, parsedName)
                ImportModeHelpers.RenderCancelButton(btnGroup)
            end)
    end)
end

return ImportMode
