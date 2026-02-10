local State = Ext.Require("Client/UI/State.lua")
local RenderHelper = Ext.Require("Client/UI/RenderHelper.lua")
local CreateModeHelpers = Ext.Require("Client/UI/Modes/CreateModeHelpers.lua")

local CreateMode = {}

function CreateMode:Render(parent)
    -- Wrap entire content in a managed group
    local group = RenderHelper.CreateManagedGroup(parent, "CreateModeContent", function(g)
        local createHeaderText = g:AddText(Loca.Get(Loca.Keys.UI_CREATE_HEADER))
        createHeaderText.TextWrapPos = 0
        g:AddSeparator()

        -- Create reactive group for input fields that updates when NewPresetData changes
        RenderHelper.CreateReactiveGroup(g, "PresetInputFields", State.NewPresetData,
            function(inputGroup, presetData)
                CreateModeHelpers.RenderInputFields(inputGroup, presetData)
            end)

        CreateModeHelpers.RenderActionButtons(g)

        g:AddSeparator()
        local detailsCH = g:AddCollapsingHeader(Loca.Get(Loca.Keys.UI_HEADER_CAPTURED_ATTRIBUTES))
        detailsCH.DefaultOpen = false

        -- Create reactive preview that updates when CapturedData changes
        RenderHelper.CreateReactiveGroup(detailsCH, "CapturedDataPreview", State.CapturedData,
            function(previewGroup, capturedData)
                CreateModeHelpers.RenderCapturedDataPreview(previewGroup, capturedData)
            end)
    end)
end

return CreateMode
