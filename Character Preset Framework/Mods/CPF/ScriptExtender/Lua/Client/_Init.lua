MCM.SetKeybindingCallback('keybinding_setting_id', function()
    Ext.Net.PostMessageToServer("CPF_trigger_callback_on_server", Ext.Json.Stringify({ skipChecks = false }))
end)

local MODVERSION = Ext.Mod.GetMod(ModuleUUID).Info.ModVersion

if MODVERSION == nil then
    CPFPrint(0, "Character Preset Framework loaded (version unknown)")
else
    table.remove(MODVERSION)

    local versionNumber = table.concat(MODVERSION, ".")
    CPFPrint(0, "Character Preset Framework (client) version " .. versionNumber .. " loaded")
end
