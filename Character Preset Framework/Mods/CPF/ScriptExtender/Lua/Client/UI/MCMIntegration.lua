MCMIntegration = {}

local Window = Ext.Require("Client/UI/Window.lua")
function MCMIntegration.Initialize()
    -- Create CPF window and render presets
    MCM.InsertModMenuTab({
        tabCallback = function(window) Window:RenderCPF(window) end,
        tabName = Loca.Get(Loca.Keys.MCM_TAB_PRESET_MANAGER)
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
                    message = Loca.Get(Loca.Keys.MCM_MSG_UNHIDDEN_SUCCESS),
                    feedbackType = "success"
                })
            else
                MCM.EventButton.ShowFeedback({
                    buttonId = "unhide_presets",
                    message = Loca.Get(Loca.Keys.MCM_MSG_UNHIDDEN_FAILURE),
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
                    message = Loca.Format(Loca.Keys.MCM_MSG_RESET_SUCCESS, loaded),
                    feedbackType = "success"
                })
            else
                MCM.EventButton.ShowFeedback({
                    buttonId = "reset_presets_index",
                    message = Loca.Get(Loca.Keys.MCM_MSG_RESET_FAILURE),
                    feedbackType = "error"
                })
            end
        end
    })

    MCM.Keybinding.SetCallback({
        settingId = 'open_cpf',
        callback = function()
            MCM.OpenModPage({
                tabName = Loca.Get(Loca.Keys.MCM_TAB_PRESET_MANAGER),
                modUUID = ModuleUUID,
                shouldEmitEvent = true
            })
        end
    })
end

return MCMIntegration
