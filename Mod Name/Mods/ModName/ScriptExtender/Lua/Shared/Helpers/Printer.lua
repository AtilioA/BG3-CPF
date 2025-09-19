MNPrinter = Printer:New { Prefix = "Mod Name", ApplyColor = true, DebugLevel = MCM.Get("debug_level") }

-- Update the Printer debug level when the setting is changed, since the value is only used during the object's creation
Ext.ModEvents.BG3MCM['MCM_Setting_Saved']:Subscribe(function(payload)
    if not payload or payload.modUUID ~= ModuleUUID or not payload.settingId then
        return
    end

    if payload.settingId == "debug_level" then
        MNDebug(0, "Setting debug level to " .. payload.value)
        MNPrinter.DebugLevel = payload.value
    end
end)

function MNPrint(debugLevel, ...)
    MNPrinter:SetFontColor(0, 255, 255)
    MNPrinter:Print(debugLevel, ...)
end

function MNTest(debugLevel, ...)
    MNPrinter:SetFontColor(100, 200, 150)
    MNPrinter:PrintTest(debugLevel, ...)
end

function MNDebug(debugLevel, ...)
    MNPrinter:SetFontColor(200, 200, 0)
    MNPrinter:PrintDebug(debugLevel, ...)
end

function MNWarn(debugLevel, ...)
    MNPrinter:SetFontColor(255, 100, 50)
    MNPrinter:PrintWarning(debugLevel, ...)
end

function MNDump(debugLevel, ...)
    MNPrinter:SetFontColor(190, 150, 225)
    MNPrinter:Dump(debugLevel, ...)
end

function MNDumpArray(debugLevel, ...)
    MNPrinter:DumpArray(debugLevel, ...)
end
