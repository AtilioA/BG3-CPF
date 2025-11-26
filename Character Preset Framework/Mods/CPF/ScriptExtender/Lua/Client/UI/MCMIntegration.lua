MCMIntegration = {}

local Window = Ext.Require("Client/UI/Window.lua")
function MCMIntegration.Initialize()
    -- Create CPF window and render presets
    MCM.InsertModMenuTab({
        tabCallback = function(window) Window:RenderCPF(window) end,
        tabName = "Preset manager"
    })

    MCM.EventButton.RegisterCallback({
        buttonId = "unhide_presets",
        callback = function()
            -- REFACTOR: make this less scattered and with mixed responsibilities
            -- Ideally, some things would be done via reactivex
            local unhid = PresetIndex:UnhideAll()
            PresetRegistry:Clear()
            PresetDiscovery:LoadPresets()
            State:RefreshPresets()
            if unhid then
                MCM.EventButton.ShowFeedback({
                    buttonId = "unhide_presets",
                    message = "All presets unhidden.",
                    feedbackType = "success"
                })
            else
                MCM.EventButton.ShowFeedback({
                    buttonId = "unhide_presets",
                    message = "Failed to unhide presets.",
                    feedbackType = "error"
                })
            end
        end
    })

    MCM.EventButton.RegisterCallback({
        buttonId = "reset_presets_index",
        callback = function()
            local cleared = PresetIndex:Clear()
            local loaded = PresetDiscovery:LoadPresets()
            if cleared and loaded >= 0 then
                MCM.EventButton.ShowFeedback({
                    buttonId = "reset_presets_index",
                    message = string.format("Preset index correctly reset.\n%d presets loaded.", loaded),
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
end

return MCMIntegration
