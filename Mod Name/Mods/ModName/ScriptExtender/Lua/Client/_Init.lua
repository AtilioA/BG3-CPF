MCM.SetKeybindingCallback('keybinding_setting_id', function()
    Ext.Net.PostMessageToServer("MN_trigger_callback_on_server", Ext.Json.Stringify({ skipChecks = false }))
end)

local MODVERSION = Ext.Mod.GetMod(ModuleUUID).Info.ModVersion

if MODVERSION == nil then
    MNPrint(0, "Mod Name loaded (version unknown)")
else
    table.remove(MODVERSION)

    local versionNumber = table.concat(MODVERSION, ".")
    MNPrint(0, "Mod Name (client) version " .. versionNumber .. " loaded")
end
