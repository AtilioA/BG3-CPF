local State = Ext.Require("Client/UI/State.lua")
local RenderHelper = Ext.Require("Client/UI/RenderHelper.lua")

local CreateMode = {}

function CreateMode:Render(parent)
    -- Wrap entire content in a managed group
    local group = RenderHelper.CreateManagedGroup(parent, "CreateModeContent", function(g)
        g:AddText("Create new preset from selected character")
        g:AddSeparator()

        -- Create reactive group for input fields that updates when NewPresetData changes
        RenderHelper.CreateReactiveGroup(g, "PresetInputFields", State.NewPresetData,
            function(inputGroup, presetData)
                inputGroup:AddText("Name")
                local inputName = inputGroup:AddInputText("")
                inputName.SameLine = true
                inputName.Text = presetData.Name
                local data = State.NewPresetData:GetValue()
                inputName.OnChange = function()
                    data.Name = inputName.Text
                end
                inputName.OnDeactivate = function()
                    State.NewPresetData:OnNext(data)
                end

                inputGroup:AddText("Author")
                local inputAuthor = inputGroup:AddInputText("")
                inputAuthor.SameLine = true
                inputAuthor.Text = presetData.Author
                inputAuthor.OnChange = function()
                    data.Author = inputAuthor.Text
                end

                inputAuthor.OnDeactivate = function()
                    State.NewPresetData:OnNext(data)
                end

                inputGroup:AddText("Version")
                local inputVer = inputGroup:AddInputText("")
                inputVer.SameLine = true
                inputVer.Text = presetData.Version
                inputVer.OnChange = function()
                    data.Version = inputVer.Text
                end

                inputVer.OnDeactivate = function()
                    State.NewPresetData:OnNext(data)
                end
            end)

        local btnSave = g:AddButton("Save")
        btnSave:SetColor("Button", UIColors.COLOR_GREEN)
        btnSave.OnClick = function()
            State:SaveNewPreset()
        end

        btnSave.SameLine = false

        local btnCancel = g:AddButton("Cancel")
        btnCancel.OnClick = function()
            State:SetMode("VIEW")
        end

        btnCancel.SameLine = true

        g:AddSeparator()
        local detailsCH = g:AddCollapsingHeader("Captured attributes (preview; for dev purposes):")
        detailsCH.DefaultOpen = false
        -- Create reactive preview that updates when CapturedData changes
        RenderHelper.CreateReactiveGroup(detailsCH, "CapturedDataPreview", State.CapturedData,
            function(previewGroup, capturedData)
                local previewChild = previewGroup:AddChildWindow("CreatePreview")
                previewChild.Size = { 0, 500 }

                if capturedData then
                    -- Show captured data
                    previewChild:AddText(Ext.Json.Stringify(capturedData))
                else
                    previewChild:AddText("No data captured.")
                end
            end)
    end)
end

return CreateMode
