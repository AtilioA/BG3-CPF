SubscribedEvents = {}

function SubscribedEvents:SubscribeToEvents()
    local function conditionalWrapper(handler)
        return function(...)
            if MCM.Get("mod_enabled") then
                handler(...)
            else
                CPFPrint(1, "Event handling is disabled.")
            end
        end
    end

    CPFDebug(2, "Subscribing to events with JSON config: " ..
        Ext.Json.Stringify(Mods.BG3MCM.MCMAPI:GetAllModSettings(ModuleUUID)))

    Ext.ModEvents.BG3MCM['MCM_Setting_Saved']:Subscribe(EHandlers.HandleMCMSettingChange)
end

return SubscribedEvents
