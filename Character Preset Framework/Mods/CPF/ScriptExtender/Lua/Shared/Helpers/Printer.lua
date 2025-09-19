CPFPrinter = Printer:New { Prefix = "Character Preset Framework", ApplyColor = true, DebugLevel = MCM.Get("debug_level") }

-- Update the Printer debug level when the setting is changed, since the value is only used during the object's creation
Ext.ModEvents.BG3MCM['MCM_Setting_Saved']:Subscribe(function(payload)
    if not payload or payload.modUUID ~= ModuleUUID or not payload.settingId then
        return
    end

    if payload.settingId == "debug_level" then
        CPFDebug(0, "Setting debug level to " .. payload.value)
        CPFPrinter.DebugLevel = payload.value
    end
end)

function CPFPrint(debugLevel, ...)
    CPFPrinter:SetFontColor(0, 255, 255)
    CPFPrinter:Print(debugLevel, ...)
end

function CPFTest(debugLevel, ...)
    CPFPrinter:SetFontColor(100, 200, 150)
    CPFPrinter:PrintTest(debugLevel, ...)
end

function CPFDebug(debugLevel, ...)
    CPFPrinter:SetFontColor(200, 200, 0)
    CPFPrinter:PrintDebug(debugLevel, ...)
end

function CPFWarn(debugLevel, ...)
    CPFPrinter:SetFontColor(255, 100, 50)
    CPFPrinter:PrintWarning(debugLevel, ...)
end

function CPFDump(debugLevel, ...)
    CPFPrinter:SetFontColor(190, 150, 225)
    CPFPrinter:Dump(debugLevel, ...)
end

function CPFDumpArray(debugLevel, ...)
    CPFPrinter:DumpArray(debugLevel, ...)
end
