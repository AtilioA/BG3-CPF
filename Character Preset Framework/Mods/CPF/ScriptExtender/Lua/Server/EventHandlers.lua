EHandlers = {}

function EHandlers.HandleMCMSettingChange(payload)
    if not payload or payload.modUUID ~= ModuleUUID or not payload.settingId then
        return
    end
    
    if payload.settingId == "debug_level" then
        CPFDebug(0, "Setting debug level to " .. payload.value)
        CPFPrinter.DebugLevel = payload.value
        -- elseif payload.settingId == "min_distance" or payload.settingId == "max_distance" then
        -- adjustDistanceSettings(payload.settingId)
    end
end

return EHandlers
