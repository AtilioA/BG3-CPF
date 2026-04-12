---Sends ApplyPreset request to server and handles response
---@param characterUuid string
---@param presetPayload table
---@param options? {DryRun?: boolean, OnSuccess?: function, OnFailure?: function}
---@return boolean requestSent
function RequestApplyPreset(characterUuid, presetPayload, options)
    options = options or {}

    -- Prepare request data
    local requestData = {
        CharacterUuid = characterUuid,
        Preset = presetPayload,
        DryRun = options.DryRun or false
    }

    -- Send request to server
    NetChannels.RequestApplyPreset:RequestToServer(requestData, function(response)
        if response.Status == "success" then
            -- Update portrait after successful apply
            if MCM and MCM.Get("auto_update_portrait") and IconManager then
                IconManager:RequestPortraitUpdate(requestData.CharacterUuid)
            end

            if options.OnSuccess then
                options.OnSuccess(response)
            end
        else
            if options.OnFailure then
                options.OnFailure(response.Warnings, response)
            end
        end
    end)

    return true
end

return RequestApplyPreset

