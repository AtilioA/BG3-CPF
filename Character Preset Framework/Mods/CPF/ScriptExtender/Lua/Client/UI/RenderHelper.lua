--- RenderHelper utilities for UI rendering
--- Follows the pattern: wrap content in a group, destroy all children before re-rendering
local RenderHelper = {}

--- Clears all children from a group
---@param group ExtuiGroup IMGUI Group element
function RenderHelper.ClearGroup(group)
    xpcall(function()
        if not group or not group.Children then return end

        for _, child in ipairs(group.Children) do
            child:Destroy()
        end
    end, function(err)
    end)
end

--- Creates a managed group that can be easily cleared and re-rendered
---@param parent ExtuiRenderable IMGUI parent element
---@param groupId string Unique identifier for the group
---@param renderFunc function Function that renders the group content, receives the group as parameter
---@return ExtuiGroup group The created group
function RenderHelper.CreateManagedGroup(parent, groupId, renderFunc)
    local group = parent:AddGroup(groupId)

    if renderFunc then
        renderFunc(group)
    end

    return group
end

--- Re-renders a managed group by clearing and calling the render function
---@param group ExtuiGroup IMGUI Group element
---@param renderFunc function Function that renders the group content
function RenderHelper.ReRender(group, renderFunc)
    RenderHelper.ClearGroup(group)
    if renderFunc then
        renderFunc(group)
    end
end

--- Creates a reactive group that subscribes to a BehaviorSubject and re-renders on changes
---@param parent ExtuiRenderable IMGUI parent element
---@param groupId string Unique identifier for the group
---@param observable BehaviorSubject BehaviorSubject to subscribe to
---@param renderFunc function Function that renders the group content, receives (group, value) as parameters
---@return ExtuiGroup group The created group
function RenderHelper.CreateReactiveGroup(parent, groupId, observable, renderFunc)
    local group = parent:AddGroup(groupId)

    -- Initial render
    local initialValue = observable:GetValue()
    if renderFunc then
        renderFunc(group, initialValue)
    end

    -- Subscribe to changes
    observable:Subscribe(function(value)
        xpcall(function()
            RenderHelper.ClearGroup(group)
            if renderFunc then
                renderFunc(group, value)
            end
        end, function(err)
        end)
    end)

    return group
end

return RenderHelper
