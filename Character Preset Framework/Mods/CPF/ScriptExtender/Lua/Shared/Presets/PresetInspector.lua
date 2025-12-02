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

--- Check if a slot should be filtered based on MCM settings
--- @param slotName string
--- @return boolean
local function ShouldFilterPrivateParts(slotName)
    if not slotName then return false end

    local hidePrivateParts = not MCM.Get('list_private_parts')
    return hidePrivateParts and slotName == "Private Parts"
end

--- Get resource details with fallback
--- @param uuid string
--- @param primaryType string
--- @param fallbackType string?
--- @return string, string
local function GetResourceName(uuid, primaryType, fallbackType)
    local name, slot = ResourceHelper:GetResourceDetails(uuid, primaryType)

    if name == "Unknown" and fallbackType then
        name, slot = ResourceHelper:GetResourceDetails(uuid, fallbackType)
    end

    return name, slot
end

--- Format resource display text
--- @param name string
--- @param slot string
--- @return string
local function FormatResourceDisplay(name, slot)
    return string.format("%s (%s)", name, slot)
end

--- Inspect simple field
--- @param value string
--- @param resourceType string
--- @return string|nil
local function InspectSimpleField(value, resourceType)
    if type(value) ~= "string" then
        return tostring(value)
    end

    local name, slot = ResourceHelper:GetResourceDetails(value, resourceType)

    -- GATING POINT: Filter private parts here
    if ShouldFilterPrivateParts(slot) then
        return nil
    end

    return FormatResourceDisplay(name, slot)
end

--- Inspect visuals array
--- @param value string[]
--- @return string[]|nil
local function InspectVisuals(value)
    if type(value) ~= "table" then return nil end

    local results = {}
    for _, uuid in ipairs(value) do
        local name, slot = GetResourceName(
            uuid,
            "CharacterCreationAppearanceVisual",
            "CharacterCreationSharedVisual"
        )

        -- Gate private parts according to MCM
        if not ShouldFilterPrivateParts(slot) then
            table.insert(results, FormatResourceDisplay(name, slot))
        end
    end

    return #results > 0 and results or nil
end

--- Inspect elements array
--- @param value table
--- @return string[]|nil
local function InspectElements(value)
    if type(value) ~= "table" then return nil end

    local results = {}
    for _, element in ipairs(value) do
        local matName = ResourceHelper:GetResourceDetails(
            element.Material,
            "CharacterCreationAppearanceMaterial"
        )

        local colName = GetResourceName(
            element.Color,
            "ColorDefinition",
            nil -- Will use default if ColorDefinition fails
        )

        if colName and colName ~= "" and colName ~= "None" and colName ~= "Unknown" then
            table.insert(results, string.format("Material: %s | Color: %s", matName, colName))
        else
            table.insert(results, string.format("Material: %s", matName))
        end
    end

    return #results > 0 and results or nil
end

--- Inspects a single value based on the field key
---@param key string
---@param value any
---@return table|string|nil
function PresetInspector:Inspect(key, value)
    if not value then return nil end

    -- Handle simple fields
    local simpleType = self.SimpleFieldMap[key]
    if simpleType then
        return InspectSimpleField(value, simpleType)
    end

    -- Handle Visuals
    if key == "Visuals" then
        return InspectVisuals(value)
    end

    -- Handle Elements
    if key == "Elements" then
        return InspectElements(value)
    end

    return nil
end

return PresetInspector
