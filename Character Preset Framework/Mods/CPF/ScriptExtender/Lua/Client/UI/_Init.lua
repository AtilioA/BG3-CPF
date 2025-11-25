local State = Ext.Require("Client/UI/State.lua")
local Window = Ext.Require("Client/UI/Window.lua")

-- Run preset discovery on client initialization
local presetCount = PresetDiscovery:LoadPresets()
CPFPrint(0, string.format("Discovered %d preset(s)", presetCount))

-- Populate UI state with discovered presets
State:RefreshPresets()

-- Create CPF window and render presets
MCM.InsertModMenuTab({
    tabCallback = function(window) Window:RenderCPF(window) end,
    tabName = "Preset manager"
})

MCM.EventButton.RegisterCallback({
    buttonId = "reset_presets_index",
    callback = function()
        local cleared = PresetIndex:Clear()
        local loaded = PresetDiscovery:LoadPresets()
        if cleared and loaded >= 0 then
            MCM.EventButton.ShowFeedback({
                buttonId = "reset_presets_index",
                message = string.format("Reset presets index. %d presets loaded.", loaded),
                feedbackType = "success"
            })
        else
            MCM.EventButton.ShowFeedback({
                buttonId = "reset_presets_index",
                message = "Failed to reset presets index.",
                feedbackType = "error"
            })
        end
    end
})

MCM.Keybinding.SetCallback({
    settingId = 'open_cpf',
    callback = function()
        MCM.OpenModPage({
            tabName = 'Preset manager',
            modUUID = ModuleUUID,
            shouldEmitEvent = true
        })
    end
})
