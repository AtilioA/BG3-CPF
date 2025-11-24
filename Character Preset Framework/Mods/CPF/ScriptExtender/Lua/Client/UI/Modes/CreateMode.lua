local State = Ext.Require("Client/UI/State.lua")
local RenderHelper = Ext.Require("Client/UI/RenderHelper.lua")
local COLOR_GREEN = { 0.2, 0.5, 0.2, 1.0 }

local CreateMode = {}

function CreateMode:Render(parent)
    -- Wrap entire content in a managed group
    local group = RenderHelper.CreateManagedGroup(parent, "CreateModeContent", function(g)
        g:AddText("Create New Preset")
        g:AddSeparator()

        -- Create reactive group for input fields that updates when NewPresetData changes
        RenderHelper.CreateReactiveGroup(g, "PresetInputFields", State.NewPresetData,
            function(inputGroup, presetData)
                local inputName = inputGroup:AddInputText("Name")
                inputName.Text = presetData.Name
                inputName.OnChange = function()
                    local data = State.NewPresetData:GetValue()
                    data.Name = inputName.Text
                    State.NewPresetData:OnNext(data)
                end

                local inputAuthor = inputGroup:AddInputText("Author")
                inputAuthor.Text = presetData.Author
                inputAuthor.OnChange = function()
                    local data = State.NewPresetData:GetValue()
                    data.Author = inputAuthor.Text
                    State.NewPresetData:OnNext(data)
                end

                local inputVer = inputGroup:AddInputText("Version")
                inputVer.Text = presetData.Version
                inputVer.OnChange = function()
                    local data = State.NewPresetData:GetValue()
                    data.Version = inputVer.Text
                    State.NewPresetData:OnNext(data)
                end
            end)

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
