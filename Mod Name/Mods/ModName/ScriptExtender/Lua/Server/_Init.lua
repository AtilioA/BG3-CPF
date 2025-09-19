-- setmetatable(Mods.ModName, { __index = Mods.VolitionCabinet })

---Ext.Require files at the path
---@param path string
---@param files string[]
function RequireFiles(path, files)
    for _, file in pairs(files) do
        Ext.Require(string.format("%s%s.lua", path, file))
    end
end

RequireFiles("Server/", {
    "Helpers/_Init",
    "EventHandlers",
    "SubscribedEvents",
})

local MODVERSION = Ext.Mod.GetMod(ModuleUUID).Info.ModVersion

if MODVERSION == nil then
    MNPrint(0, "Mod Name loaded (version unknown)")
else
    table.remove(MODVERSION)

    local versionNumber = table.concat(MODVERSION, ".")
    MNPrint(0, "Mod Name version " .. versionNumber .. " loaded")
end

SubscribedEvents.SubscribeToEvents()
