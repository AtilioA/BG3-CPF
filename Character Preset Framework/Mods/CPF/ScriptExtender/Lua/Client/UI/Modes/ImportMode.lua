local State = Ext.Require("Client/UI/State.lua")
local RenderHelper = Ext.Require("Client/UI/RenderHelper.lua")

local ImportMode = {}

--- Attempts to parse preset name from buffer
--- @param buffer string
--- @return string|nil presetName
function ImportMode:ParsePresetName(buffer)
    if not buffer or buffer == "" then
        return nil
    end

    -- Try to parse the JSON and extract the preset name
    local success, result = xpcall(
        function()
            if Preset and Preset.Deserialize then
                local preset, err = Preset.Deserialize(buffer)
                if err then
                    CPFWarn(0, err)
                    State:SetStatus(err)
                end
                if preset and preset.Name then
                    return preset.Name
                end
            end
            return nil
        end,
        function(err)
            CPFWarn(0, err)
            return nil
        end
    )

    if success and result then
        return result
    end

    return nil
end

function ImportMode:Render(parent)
    -- Wrap entire content in a managed group
    RenderHelper.CreateManagedGroup(parent, "ImportModeContent", function(group)
        if (not Ext.Debug.IsDeveloperMode()) and (Ext.Utils.Version() <= 30) then
            group:AddText(Loca.Get(Loca.Keys.UI_ERROR_SE_VERSION))
            CPFWarn(1, "Import feature is still not available!")
            return false
        end
        group:AddText(Loca.Get(Loca.Keys.UI_MSG_PASTE_JSON))

        local input = group:AddInputText("")
        input.Multiline = true
        input.SizeHint = { 450, 400 }
        -- input.Text = State.ImportBuffer:GetValue()
        input.OnChange = function()
            -- State.ImportBuffer:OnNext(input.Text)
        end

        -- Create reactive button group that updates when ImportBuffer changes
        RenderHelper.CreateReactiveGroup(group, "ImportButtonGroup", State.ImportBuffer,
            function(btnGroup, buffer)
                local parsedName = ImportMode:ParsePresetName(buffer)
                -- Determine button label based on parsed preset name
                local buttonLabel = Loca.Get(Loca.Keys.UI_BUTTON_IMPORT)
                if parsedName then
                    buttonLabel = Loca.Format(Loca.Keys.UI_BUTTON_IMPORT_NAMED, parsedName)
                end

                local btnImport = btnGroup:AddButton(buttonLabel)

                if parsedName then
                    btnImport:SetColor("Button", UIColors.COLOR_GREEN)
                    StyleHelpers.EnableButton(btnImport)
                else
                    StyleHelpers.DisableButton(btnImport)
                end
                btnImport.OnClick = function()
                    State:ImportFromBuffer()
                end

                btnImport.SameLine = false

                local btnCancel = btnGroup:AddButton(Loca.Get(Loca.Keys.UI_BUTTON_CANCEL))
                btnCancel.OnClick = function()
                    State:SetMode("VIEW")
                    State.ImportBuffer:OnNext("")
                end

                btnCancel.SameLine = true
            end)
    end)
end

return ImportMode
