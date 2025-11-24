UserID = {}

-- Returns the character that the user is controlling
---@param userId integer The user ID
---@return EntityHandle|nil The character entity, or nil if not found
function UserID:GetUserCharacter(userId)
    for _, entity in pairs(Ext.Entity.GetAllEntitiesWithComponent("ClientControl")) do
        if entity.UserReservedFor.UserID == userId then
            return entity
        end
    end

    return nil
end

return UserID
