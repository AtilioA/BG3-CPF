---Sends RequestUserInfo request to server and handles response
---@param options? {OnSuccess?: function, OnFailure?: function}
---@return boolean requestSent
function RequestUserInfo(options)
    options = options or {}

    -- Send request to server
    NetChannels.RequestUserInfo:RequestToServer({}, function(response)
        if response.Status == "success" then
            if options.OnSuccess then
                options.OnSuccess(response)
            end
        else
            if options.OnFailure then
                options.OnFailure(response)
            end
        end
    end)

    return true
end

return RequestUserInfo
