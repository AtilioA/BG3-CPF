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

    Ext.ModEvents.BG3MCM['MCM_Setting_Saved']:Subscribe(EHandlers.HandleMCMSettingChange)
end

return SubscribedEvents
