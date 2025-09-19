SubscribedEvents = {}

function SubscribedEvents:SubscribeToEvents()
    local function conditionalWrapper(handler)
        return function(...)
            if MCM.Get("mod_enabled") then
                handler(...)
            else
                MNPrint(1, "Event handling is disabled.")
            end
        end
    end

    MNDebug(2, "Subscribing to events with JSON config: " ..
        Ext.Json.Stringify(Mods.BG3MCM.MCMAPI:GetAllModSettings(ModuleUUID)))


    -- Examples for event subscription + event handlers as callbacks

    Ext.Osiris.RegisterListener("AutomatedDialogStarted", 2, "before",
        conditionalWrapper(EHandlers.OnAutomatedDialogStarted))

    -- Ext.Osiris.RegisterListener("AutomatedDialogEnded", 2, "after", conditionalWrapper(EHandlers.OnAutomatedDialogEnded))

    Ext.Osiris.RegisterListener("AutomatedDialogForceStopping", 2, "after",
        conditionalWrapper(EHandlers.OnAutomatedDialogForceStopping))

    Ext.Osiris.RegisterListener("InstanceDialogChanged", 4, "after",
        conditionalWrapper(function(oldDialog, oldDialogStopping, instanceID, newDialog)
            MNPrint(2,
                "InstanceDialogChanged: " ..
                oldDialog .. " " .. oldDialogStopping .. " " .. instanceID .. " " .. newDialog)
        end))

    Ext.Osiris.RegisterListener("TimerFinished", 1, "after", conditionalWrapper(EHandlers.OnTimerFinished))

    Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", conditionalWrapper(EHandlers.OnLevelGameplayStarted))

    Ext.ModEvents.BG3MCM['MCM_Setting_Saved']:Subscribe(EHandlers.HandleMCMSettingChange)
end

return SubscribedEvents
