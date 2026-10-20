--- Keeps the server registry equal to the host client's catalog, in memory, and relays it to guests.
--- A message with Records comes from the host after a change; one without Records is a guest asking for the catalog.
local HOST_PEER_ID = 1

---@param data { Records: table<string, PresetRecord>? }
---@param userId integer Packed network user id: (peerId << 16) | userIndex
local function handlePresetCatalog(data, userId)
    if data.Records then
        if userId >> 16 ~= HOST_PEER_ID then
            CPFWarn(1, "Ignoring a preset catalog from a guest client")
            return
        end

        PresetRegistry.ReplaceAll(data.Records)
        NetChannels.PresetCatalog:Broadcast(data)
        return
    end

    API.EnsurePresetRegistryLoaded()
    NetChannels.PresetCatalog:SendToClient({ Records = PresetRegistry.GetAll() }, userId)
end

NetChannels.PresetCatalog:SetHandler(handlePresetCatalog)
