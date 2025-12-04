MCMIntegration = {}

local Window = Ext.Require("Client/UI/Window.lua")
local State = Ext.Require("Client/UI/State.lua")

function MCMIntegration.Initialize()
    -- Create CPF window and render presets
    MCM.InsertModMenuTab("Preset manager", function(window)
        Window:RenderCPF(window)
    end, ModuleUUID)

    MCM.EventButton.RegisterCallback("unhide_presets", function()
        -- REFACTOR: make this less scattered and with mixed responsibilities
        -- Ideally, some things would be done via reactivex
        local unhid = PresetIndex:UnhideAll()
        PresetRegistry:Clear()
        PresetDiscovery:LoadPresets()
        State:RefreshPresets()
        if unhid then
            MCM.EventButton.ShowFeedback(
                "unhide_presets",
                Loca.Get(Loca.Keys.MCM_MSG_UNHIDDEN_SUCCESS),
                "success"
            )
        else
            MCM.EventButton.ShowFeedback(
                "unhide_presets",
                Loca.Get(Loca.Keys.MCM_MSG_UNHIDDEN_FAILURE),
                "error"
            )
        end
    end)

    MCM.EventButton.RegisterCallback("reset_presets_index", function()
        local cleared = PresetIndex:Clear()
        local loaded = PresetDiscovery:LoadPresets()
        if cleared and loaded >= 0 then
            MCM.EventButton.ShowFeedback(
                "reset_presets_index",
                Loca.Format(Loca.Keys.MCM_MSG_RESET_SUCCESS, loaded),
                "success"
            )
        else
            MCM.EventButton.ShowFeedback(
                "reset_presets_index",
                Loca.Get(Loca.Keys.MCM_MSG_RESET_FAILURE),
                "error"
            )
        end
    end)

    MCM.Keybinding.SetCallback('open_cpf', function()
        MCM.OpenModPage(
            Loca.Get(Loca.Keys.MCM_TAB_PRESET_MANAGER),
            ModuleUUID,
            true
        )
    end)
end

function MCMIntegration.Initialize_MCM_1_38()
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
