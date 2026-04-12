--- Server-side handler for icon update requests from clients

--- Applies a rendered icon to an entity and replicates to all clients
---@param entity EntityHandle
---@param icon ScratchBuffer webp binary
local function setIcon(entity, icon)
    local customIconComp = entity.CustomIcon or entity:CreateComponent("CustomIcon")
    customIconComp.Icon = icon
    customIconComp.Source = 0
    entity:Replicate("CustomIcon")

    local iconComp = entity.Icon or entity:CreateComponent("Icon")
    iconComp.Icon = "CustomIconSet"
    entity:Replicate("Icon")
end

---@param data {Icon: ScratchBuffer, Target: string}
---@param userId integer
local function handleIconUpdate(data, userId)
    if not data.Target or not data.Icon then
        CPFWarn(0, "HandleIconUpdate: Missing Target or Icon data")
        return
    end

    local entity = Ext.Entity.Get(data.Target)
    if not entity then
        CPFWarn(0, "HandleIconUpdate: Entity not found: " .. tostring(data.Target))
        return
    end

    setIcon(entity, data.Icon)
    CPFPrint(1, "HandleIconUpdate: Updated portrait for " .. tostring(data.Target))
end

NetChannels.IconUpdate:SetHandler(handleIconUpdate)
