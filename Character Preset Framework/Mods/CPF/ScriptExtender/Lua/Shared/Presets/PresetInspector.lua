local ResourceHelper = Ext.Require("Shared/Helpers/ResourceHelper.lua")

---@class PresetInspector
local PresetInspector = {}

--- Map simple fields to resource types
--- @alias SimpleFieldMap string
PresetInspector.SimpleFieldMap = {
    EyeColor = "CharacterCreationEyeColor",
    HairColor = "CharacterCreationHairColor",
    SkinColor = "CharacterCreationSkinColor",
    SecondEyeColor = "CharacterCreationEyeColor",
    AccessorySet = "CharacterCreationAccessorySet",
}

--- Inspects a single value based on the field key
---@param key string
---@param value any
---@return table|string|nil
function PresetInspector:Inspect(key, value)
    if not value then return nil end

    -- Handle simple fields
    local simpleType = self.SimpleFieldMap[key]
    if simpleType then
        if type(value) == "string" then
            local name, slot = ResourceHelper:GetResourceDetails(value, simpleType)
            return string.format("%s (%s)", name, slot)
        end
        return tostring(value)
    end

    -- Handle Visuals
    if key == "Visuals" and type(value) == "table" then
        local results = {}
        for _, uuid in ipairs(value) do
            -- Try AppearanceVisual first, then SharedVisual
            local name, slot = ResourceHelper:GetResourceDetails(uuid, "CharacterCreationAppearanceVisual")
            if name == "Unknown" then
                name, slot = ResourceHelper:GetResourceDetails(uuid, "CharacterCreationSharedVisual")
            end
            table.insert(results, string.format("%s (%s)", name, slot))
        end
        return results
    end

    -- Handle Elements
    if key == "Elements" and type(value) == "table" then
        local results = {}
        for i, element in ipairs(value) do
            local matName, _ = ResourceHelper:GetResourceDetails(element.Material, "CharacterCreationAppearanceMaterial")
            local colName, _ = ResourceHelper:GetResourceDetails(element.Color, "ColorDefinition")

            -- Fallback for color
            if colName == "Unknown" then
                colName, _ = ResourceHelper:GetResourceDetails(element.Color)
            end

            table.insert(results, string.format("Material: %s | Color: %s", matName, colName))
        end
        return results
    end

    return nil
end

return PresetInspector
