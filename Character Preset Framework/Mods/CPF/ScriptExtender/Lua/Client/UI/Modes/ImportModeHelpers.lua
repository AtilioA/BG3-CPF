local State = Ext.Require("Client/UI/State.lua")

local ImportModeHelpers = {}

--- Attempts to parse preset name from buffer
--- @param buffer string
--- @return string|nil presetName
function ImportModeHelpers.ParsePresetName(buffer)
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

function ImportModeHelpers.GetButtonLabel(parsedName)
    if parsedName then
        return Loca.Format(Loca.Keys.UI_BUTTON_IMPORT_NAMED, parsedName)
    else
        return Loca.Get(Loca.Keys.UI_BUTTON_IMPORT)
    end
end

function ImportModeHelpers.RenderImportButton(btnGroup, parsedName)
    local buttonLabel = ImportModeHelpers.GetButtonLabel(parsedName)
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

    return btnImport
end

function ImportModeHelpers.RenderCancelButton(btnGroup)
    local btnCancel = btnGroup:AddButton(Loca.Get(Loca.Keys.UI_BUTTON_CANCEL))
    btnCancel.OnClick = function()
        State:SetMode("VIEW")
        State.ImportBuffer:OnNext("")
    end
    btnCancel.SameLine = true

    return btnCancel
end

return ImportModeHelpers
