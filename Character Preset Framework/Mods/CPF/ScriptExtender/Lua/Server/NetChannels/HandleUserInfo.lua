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
        CharacterName = ""
    }

    -- Get user name
    local userName = Osi.GetUserName(userId)
    if userName then
        response.UserName = userName
    end

    -- Get character entity for this user
    local entity = UserID:GetUserCharacter(userId)
    if entity then
        response.CharacterName = Ext.Loca.GetTranslatedString(entity.DisplayName.NameKey.Handle.Handle)
    end

    CPFPrint(1, string.format("Returning user info: %s, character: %s",
        response.UserName, response.CharacterName))

    return response
end

local function initServerHandlers()
    NetChannels.RequestUserInfo:SetRequestHandler(handleUserInfo)
end

initServerHandlers()
