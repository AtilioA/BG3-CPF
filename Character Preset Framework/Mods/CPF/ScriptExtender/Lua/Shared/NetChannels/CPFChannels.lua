---Shared netchannels for CPF server-client communication
---@class CPFNetChannels
---@field RequestApplyPreset ExtenderNetChannel
NetChannels = {}

---Creates and returns a netchannel with the given name
---@param channelName string
---@return ExtenderNetChannel
local function createChannel(channelName)
    ---@type ExtenderNetChannel
    local channel = Ext.Net.CreateChannel(ModuleUUID, channelName)
    return channel
end

---RequestApplyPreset channel for applying character presets
---@class RequestApplyPresetChannel : ExtenderNetChannel
NetChannels.RequestApplyPreset = createChannel("RequestApplyPreset")

return NetChannels
