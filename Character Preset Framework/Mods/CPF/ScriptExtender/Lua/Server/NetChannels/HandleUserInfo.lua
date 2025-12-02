---Server-side handler for RequestUserInfo

---Handles RequestUserInfo requests from clients
---@param data table
---@param userId integer
---@return table response
local function handleUserInfo(data, userId)
    CPFPrint(1, "Received RequestUserInfo request from client")

    local response = {
        Status = "success",
        UserName = "",
        UserID = userId
    }

    -- Get user name
    local userName = Osi.GetUserName(userId)
    if userName then
        response.UserName = userName
    end

    CPFPrint(1, string.format("Returning user info: %s", response.UserName))

    return response
end

local function initServerHandlers()
    NetChannels.RequestUserInfo:SetRequestHandler(handleUserInfo)
end

initServerHandlers()
