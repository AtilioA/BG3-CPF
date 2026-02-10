local State = Ext.Require("Client/UI/State.lua")

local CreateModeHelpers = {}

function CreateModeHelpers.CreateInputField(group, labelKey, fieldName, presetData)
    local labelText = group:AddText(Loca.Get(labelKey))
    labelText.TextWrapPos = 0
    local input = group:AddInputText("")
    input.SameLine = true
    input.Text = presetData[fieldName]

    local data = State.NewPresetData:GetValue()
    input.OnChange = function()
        data[fieldName] = input.Text
    end

    input.OnDeactivate = function()
        State.NewPresetData:OnNext(data)
    end

    return input
end

function CreateModeHelpers.RenderInputFields(inputGroup, presetData)
    CreateModeHelpers.CreateInputField(inputGroup, Loca.Keys.UI_LABEL_NAME, "Name", presetData)
    CreateModeHelpers.CreateInputField(inputGroup, Loca.Keys.UI_LABEL_AUTHOR, "Author", presetData)
    CreateModeHelpers.CreateInputField(inputGroup, Loca.Keys.UI_LABEL_VERSION, "Version", presetData)
end

function CreateModeHelpers.RenderActionButtons(group)
    local btnSave = group:AddButton(Loca.Get(Loca.Keys.UI_BUTTON_SAVE))
    btnSave:SetColor("Button", UIColors.COLOR_GREEN)
    btnSave.OnClick = function()
        State:SaveNewPreset()
    end
    btnSave.SameLine = false

    local btnCancel = group:AddButton(Loca.Get(Loca.Keys.UI_BUTTON_CANCEL))
    btnCancel.OnClick = function()
        State:SetMode("VIEW")
    end
    btnCancel.SameLine = true

    return btnSave, btnCancel
end

function CreateModeHelpers.RenderCapturedDataPreview(previewGroup, capturedData)
    local previewChild = previewGroup:AddChildWindow("CreatePreview")
    previewChild.Size = { 0, 500 }

    if capturedData then
        -- Show captured data
        local capturedDataText = previewChild:AddText(Ext.Json.Stringify(capturedData))
        capturedDataText.TextWrapPos = 0
    else
        local noDataText = previewChild:AddText(Loca.Get(Loca.Keys.UI_MSG_NO_DATA_CAPTURED))
        noDataText.TextWrapPos = 0
    end
end

return CreateModeHelpers
