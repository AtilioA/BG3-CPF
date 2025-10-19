local MODVERSION = Ext.Mod.GetMod(ModuleUUID).Info.ModVersion

if MODVERSION == nil then
    CPFPrint(0, "Character Preset Framework loaded (version unknown)")
else
    table.remove(MODVERSION)

    local versionNumber = table.concat(MODVERSION, ".")
    CPFPrint(0, "Character Preset Framework (client) version " .. versionNumber .. " loaded")
end

Ext.Events.ResetCompleted:Subscribe(function()
    CPFDebug(0, "Reset completed, dumping CCA")
    _DS(_C().CharacterCreationAppearance)
    CPFDumpCCA(1, _C().CharacterCreationAppearance)
end)

RequireFiles("Client/NetChannels/", {
    "_Init",
})
