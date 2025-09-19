EHandlers = {}

function EHandlers.HandleMCMSettingChange(call, payload)
    if payload.settingId == "debug_level" then
        CPFDebug(0, "Setting debug level to " .. payload.value)
        CPFPrinter.DebugLevel = payload.value
        -- elseif payload.settingId == "min_distance" or payload.settingId == "max_distance" then
        -- adjustDistanceSettings(payload.settingId)
    end
end

return EHandlers
