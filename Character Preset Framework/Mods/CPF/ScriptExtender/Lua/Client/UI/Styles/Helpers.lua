StyleHelpers = {}

--- DisabledAlpha exists, but I don't know how to use it (?)
--- Sets button style to more transparent and disable it
function StyleHelpers.DisableButton(button)
    button:SetStyle("Alpha", 0.5)
    button.Disabled = true
end

--- Sets button style to less transparent and enable it
function StyleHelpers.EnableButton(button)
    button:SetStyle("Alpha", 1.0)
    button.Disabled = false
end

-- function StyleHelpers.SetButtonActive(button)
--     for _, child in ipairs(button.Parent.Children) do
--         if not child.UserData then
--             child.UserData = {}
--         end
--         -- Check if the IDContext ends with the uuid
--         if child.IDContext and child.IDContext:sub(- #uuid) == uuid then
--             if not child.UserData.originalText then
--                 child.UserData.originalText = child.Label
--             end
--             child.Label = "> " .. child.UserData.originalText
--             child:SetColor("Button", UIStyle.Colors["ButtonActive"])
--         else
--             -- Restore original text for inactive items
--             if child.UserData.originalText then
--                 child.Label = child.UserData.originalText
--             end
--             child:SetColor("Button", UIStyle.Colors["Button"])
--         end
--     end
-- end


return StyleHelpers
