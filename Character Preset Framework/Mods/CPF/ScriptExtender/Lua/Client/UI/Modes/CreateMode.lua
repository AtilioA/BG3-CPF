local State = Ext.Require("Client/UI/State.lua")
local RenderHelper = Ext.Require("Client/UI/RenderHelper.lua")
local COLOR_GREEN = { 0.2, 0.5, 0.2, 1.0 }

local CreateMode = {}

function CreateMode:Render(parent)
    -- Wrap entire content in a managed group
    local group = RenderHelper.CreateManagedGroup(parent, "CreateModeContent", function(g)
        g:AddText("Create New Preset")
        g:AddSeparator()

        -- TODO: add netchannel request to server asking user named and character name
        -- TODO: Default to character's name
        local inputName = g:AddInputText("Name")
        inputName.Text = State.NewPresetData.Name
        inputName.OnChange = function() State.NewPresetData.Name = inputName.Text end

        -- TODO: Default to user name
        -- Osi.GetUserName(userId)) (only on server)
        local inputAuthor = g:AddInputText("Author")
        inputAuthor.Text = State.NewPresetData.Author

        inputAuthor.OnChange = function() State.NewPresetData.Author = inputAuthor.Text end

        local inputVer = g:AddInputText("Version")
        inputVer.Text = State.NewPresetData.Version
        inputVer.OnChange = function() State.NewPresetData.Version = inputVer.Text end

        g:AddSeparator()
        g:AddText("Captured attributes (preview):")

        -- Create reactive preview that updates when CapturedData changes
        RenderHelper.CreateReactiveGroup(g, "CapturedDataPreview", State.CapturedData,
            function(previewGroup, capturedData)
                local previewChild = previewGroup:AddChildWindow("CreatePreview")
                previewChild.Size = { 0, 250 }

                if capturedData then
                    -- Show captured data
                    previewChild:AddText(Ext.Json.Stringify(capturedData))
                else
                    previewChild:AddText("No data captured.")
                end
            end)

        local btnSave = g:AddButton("Save")
        btnSave:SetColor("Button", COLOR_GREEN)
        btnSave.OnClick = function()
            State:SaveNewPreset()
        end

        btnSave.SameLine = false

        local btnCancel = g:AddButton("Cancel")
        btnCancel.OnClick = function()
            State:SetMode("VIEW")
        end

        btnCancel.SameLine = true
    end)
end

return CreateMode
