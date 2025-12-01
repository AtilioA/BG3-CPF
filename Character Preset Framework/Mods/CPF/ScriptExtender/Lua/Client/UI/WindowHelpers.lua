local State = Ext.Require("Client/UI/State.lua")
local PresetCompatibility = Ext.Require("Shared/Validation/PresetCompatibility.lua")

local WindowHelpers = {}

function WindowHelpers.GetSortedPresets(records)
    local compatible = {}
    local incompatible = {}
    local character = nil
    if State.TargetCharacterUUID then
        character = Ext.Entity.Get(State.TargetCharacterUUID)
    end
    if not character then character = _C() end

    for _, record in ipairs(records) do
        local isCompatible = true
        if PresetCompatibility and character and record.preset then
            local warnings = PresetCompatibility.Check(record.preset, character)
            if #warnings > 0 then isCompatible = false end
        end

        if isCompatible then
            table.insert(compatible, record)
        else
            table.insert(incompatible, record)
        end
    end

    local sortFunc = function(a, b)
        local nameA = (a.preset and a.preset.Name) or ""
        local nameB = (b.preset and b.preset.Name) or ""
        return nameA < nameB
    end
    table.sort(compatible, sortFunc)
    table.sort(incompatible, sortFunc)

    return compatible, incompatible
end

function WindowHelpers.AddPresetRow(presetsTable, record, isCompatible)
    local row = presetsTable:AddRow()
    local nameCell = row:AddCell()
    local label = (record.preset.Name .. "##" .. record.preset._id) or ("Preset " .. record.preset._id)

    local item = nameCell:AddButton(label)
    item.Size = { -1, 50 }
    item.UserData = {
        isCompatible = isCompatible,
        record = record
    }
    if not isCompatible then
        item:SetColor("Button", UIColors.BUTTON_DISABLED)
        item:SetColor("Text", Mods.BG3MCM.UIStyle.Colors.TextDisabled)
    end
    item.OnClick = function()
        State:SelectPreset(record)
    end
    return item
end

function WindowHelpers.UpdateActivePresetButton(presetsTable, selected)
    if not selected then return nil end
    local activeProfileButton = nil
    for _, child in ipairs(presetsTable.Children) do
        local cellChild = child.Children[1].Children[1]
        if Ext.Types.IsA(cellChild, "extui::Button") then
            if cellChild.Label == selected.preset.Name .. "##" .. selected.preset._id then
                activeProfileButton = cellChild
                cellChild:SetColor("Button", Mods.BG3MCM.UIStyle.Colors.ButtonActive)
            else
                if cellChild.UserData.isCompatible then
                    cellChild:SetColor("Button", Mods.BG3MCM.UIStyle.Colors.Button)
                else
                    cellChild:SetColor("Button", UIColors.BUTTON_DISABLED)
                end
            end
        end
    end
    return activeProfileButton
end

return WindowHelpers
