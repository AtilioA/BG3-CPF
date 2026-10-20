--- Shares the host's preset catalog. The host client sends its records to the server whenever the
--- UI preset list refreshes; the server relays them, and guest clients use them instead of their own.
local State = Ext.Require("Client/UI/State.lua")

State.Presets:Subscribe(function()
    -- Client-side, IsHost means this client runs the server (the host or its split-screen player)
    if Ext.Net.IsHost() then
        NetChannels.PresetCatalog:SendToServer({ Records = PresetRegistry.GetAll() })
    end
end)

NetChannels.PresetCatalog:SetHandler(function(data)
    if Ext.Net.IsHost() then
        return
    end

    PresetRegistry.ReplaceAll(data.Records)
    State:RefreshPresets()
end)

Ext.Events.SessionLoaded:Subscribe(function()
    if not Ext.Net.IsHost() then
        NetChannels.PresetCatalog:SendToServer({})
    end
end)
