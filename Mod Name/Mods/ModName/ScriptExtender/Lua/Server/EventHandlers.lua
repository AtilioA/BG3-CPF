EHandlers = {}

-- Examples for event handlers

function EHandlers.OnAutomatedDialogStarted(dialog, instanceID)
    MNPrint(2, "AutomatedDialogStarted: " .. dialog .. " " .. instanceID)
end

function EHandlers.OnAutomatedDialogEnded(dialog, instanceID)
    MNPrint(2, "AutomatedDialogEnded: " .. dialog .. " " .. instanceID)
    -- Calculate duration based on last played time
    -- ...
end

function EHandlers.OnTimerFinished(timer)
    -- if timer begins with "PostponeDialog" then...
    if string.find(timer, "PostponeDialog") == 1 then
        MNPrint(2, "TimerFinished: " .. timer)
        local dialog = string.sub(timer, 15)
        if EHandlers.dialogs[dialog] and EHandlers.dialogs[dialog].instances and #EHandlers.dialogs[dialog].instances > 0 then
            EHandlers.handling_dialogs[dialog] = false
            EHandlers.should_handle[dialog] = false
        end
    elseif timer == "ResetBanterIntervals" then
        MNPrint(2, "TimerFinished: " .. timer)
    end
end

function EHandlers.OnLevelGameplayStarted(isEditorMode, levelName)
    if MCM.Get("reset_on_timer") > 0 then
        Osi.TimerLaunch("ResetBanterIntervals", MCM.Get("reset_on_timer") * 1000)
    end
end

function EHandlers.OnAutomatedDialogForceStopping(dialog, instanceID)
    MNPrint(3, "AutomatedDialogForceStopping: " .. dialog .. " " .. instanceID)
end

function EHandlers.HandleMCMSettingChange(call, payload)
    -- Make sure the ranges are consistent
    local function adjustDistanceSettings(changedSetting)
        local minDistanceForFactor = MCM.Get("distance_factor_scaling_min_distance")
        local maxDistanceForFactor = MCM.Get("distance_factor_scaling_max_distance")

        if changedSetting == "min_distance" and minDistanceForFactor > maxDistanceForFactor then
            MCM.Set("max_distance", minDistanceForFactor)
        elseif changedSetting == "max_distance" and maxDistanceForFactor < minDistanceForFactor then
            MCM.Set("min_distance", maxDistanceForFactor)
        end
    end

    -- Make sure the ranges are consistent
    local function adjustIntervalSettings(changedSetting)
        local minInterval = MCM.Get("min_interval_bonus")
        local maxInterval = MCM.Get("max_interval_bonus")

        if changedSetting == "min_interval_bonus" and minInterval > maxInterval then
            MCM.Set("max_interval_bonus", minInterval)
        elseif changedSetting == "max_interval_bonus" and maxInterval < minInterval then
            MCM.Set("min_interval_bonus", maxInterval)
        end
    end

    if not payload or payload.modUUID ~= ModuleUUID or not payload.settingId then
        return
    end

    if payload.settingId == "debug_level" then
        MNDebug(0, "Setting debug level to " .. payload.value)
        MNPrinter.DebugLevel = payload.value
    elseif payload.settingId == "min_distance" or payload.settingId == "max_distance" then
        adjustDistanceSettings(payload.settingId)
    elseif payload.settingId == "min_interval_bonus" or payload.settingId == "max_interval_bonus" then
        adjustIntervalSettings(payload.settingId)
    end
end

return EHandlers
