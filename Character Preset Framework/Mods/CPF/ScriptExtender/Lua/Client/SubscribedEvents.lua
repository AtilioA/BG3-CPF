local State = Ext.Require("Client/UI/State.lua")

local function clientControlCreated(entity, ct, c)
    if entity.UserReservedFor == nil or entity.UserReservedFor.UserID ~= 1 then return end
    State:OnCharacterChanged(entity)
end

Ext.Entity.OnCreate("ClientControl", clientControlCreated)
