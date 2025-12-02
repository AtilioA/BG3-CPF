---@class ResourceHelper
local ResourceHelper = {}

-- A subset of ExtResourceManagerType
--- @alias PartialExtResourceManagerType string|"CharacterCreationAccessorySet"|"CharacterCreationAppearanceMaterial"|"CharacterCreationAppearanceVisual"|"CharacterCreationEquipmentIcons"|"CharacterCreationEyeColor"|"CharacterCreationHairColor"|"CharacterCreationIconSettings"|"CharacterCreationMaterialOverride"|"CharacterCreationPassiveAppearance"|"CharacterCreationPreset"|"CharacterCreationSharedVisual"|"CharacterCreationSkinColor"|"CharacterCreationVOLine"|"ColorDefinition"
ResourceHelper.ResourceTypes = {
    "CharacterCreationAccessorySet",
    "CharacterCreationAppearanceMaterial",
    "CharacterCreationAppearanceVisual",
    "CharacterCreationEquipmentIcons",
    "CharacterCreationEyeColor",
    "CharacterCreationIconSettings",
    "CharacterCreationHairColor",
    "CharacterCreationMaterialOverride",
    "CharacterCreationPassiveAppearance",
    "CharacterCreationPreset",
    "CharacterCreationSharedVisual",
    "CharacterCreationSkinColor",
    "CharacterCreationVOLine",
    "ColorDefinition"
}

ResourceHelper.UnwantedCharacters = {
    "★ ",
}

function ResourceHelper:CleanDisplayName(displayName)
    for _, char in ipairs(ResourceHelper.UnwantedCharacters) do
        displayName = string.gsub(displayName, char, "")
    end
    return displayName
end

--- Helper to safely get display name
--- Removes unwanted charactersSet (★) from the display nameet---@param resource any
---@return string
local function GetDisplayName(resource)
    if resource.DisplayName and resource.DisplayName.Get then
        local displayName = resource.DisplayName:Get()
        -- Remove the "★ " marker at the source
        local cleaned = ResourceHelper:CleanDisplayName(displayName)
        return cleaned
    end
    return ""
end

--- Strategy table for extracting resource details
---@type table<string, fun(resource: any): string, string>
ResourceHelper.Strategies = {
    -- Types that have a SlotName
    CharacterCreationAppearanceVisual = function(resource)
        return GetDisplayName(resource), resource.SlotName or "Unknown"
    end,
    CharacterCreationSharedVisual = function(resource)
        return GetDisplayName(resource), resource.SlotName or "Unknown"
    end,
    CharacterCreationAccessorySet = function(resource)
        return GetDisplayName(resource), resource.SlotName or "Unknown"
    end,

    -- Types that need a static slot name
    CharacterCreationSkinColor = function(resource)
        return GetDisplayName(resource), Loca.Get(Loca.Keys.RESOURCE_SKIN_COLOR)
    end,
    CharacterCreationEyeColor = function(resource)
        return GetDisplayName(resource), Loca.Get(Loca.Keys.RESOURCE_EYE_COLOUR)
    end,
    CharacterCreationHairColor = function(resource)
        return GetDisplayName(resource), Loca.Get(Loca.Keys.RESOURCE_HAIR_COLOUR)
    end,
    CharacterCreationAppearanceMaterial = function(resource)
        return GetDisplayName(resource), Loca.Get(Loca.Keys.RESOURCE_MATERIAL)
    end,
    CharacterCreationMaterialOverride = function(resource)
        return GetDisplayName(resource), Loca.Get(Loca.Keys.RESOURCE_MATERIAL_OVERRIDE)
    end,
    CharacterCreationPassiveAppearance = function(resource)
        return GetDisplayName(resource), Loca.Get(Loca.Keys.RESOURCE_PASSIVE_FEATURE)
    end,
    CharacterCreationPreset = function(resource)
        return GetDisplayName(resource), Loca.Get(Loca.Keys.RESOURCE_PRESET)
    end,
    CharacterCreationVOLine = function(resource)
        return GetDisplayName(resource), Loca.Get(Loca.Keys.RESOURCE_VOICE_LINE)
    end,
    ColorDefinition = function(resource)
        return GetDisplayName(resource), Loca.Get(Loca.Keys.RESOURCE_COLOUR_DEFINITION)
    end,
    CharacterCreationEquipmentIcons = function(resource)
        return GetDisplayName(resource), Loca.Get(Loca.Keys.RESOURCE_EQUIPMENT_ICON)
    end,
    CharacterCreationIconSettings = function(resource)
        return GetDisplayName(resource), Loca.Get(Loca.Keys.RESOURCE_ICON_SETTINGS)
    end,
}

--- Safely executes a strategy function
---@param strategy fun(resource: any): string, string
---@param resource any
---@return string displayName, string slotName
function ResourceHelper:SafeExecute(strategy, resource)
    local success, name, slot = pcall(strategy, resource)
    if success then
        return name, slot
    end
    CPFWarn(2, "Failed to get resource details.")
    return "Unknown", "Unknown"
end

--- Gets details for a specific resource
---@param resourceUUID string
---@param resourceType string|nil Optional type hint
---@return string displayName, string slotName
function ResourceHelper:GetResourceDetails(resourceUUID, resourceType)
    if not resourceUUID or resourceUUID == "" or resourceUUID == Constants.NULL_UUID then
        return
            "None", "None"
    end

    local resource = nil
    local foundType = nil

    if resourceType then
        resource = Ext.StaticData.Get(resourceUUID, resourceType)
        if resource then
            foundType = resourceType
        end
    else
        -- Try all resource types
        for _, type in ipairs(self.ResourceTypes) do
            resource = Ext.StaticData.Get(resourceUUID, type)
            if resource then
                foundType = type
                break
            end
        end
    end

    if not resource then return "Unknown", "Unknown" end

    local strategy = self.Strategies[foundType]
    if strategy then
        return self:SafeExecute(strategy, resource)
    end

    -- Fallback strategy
    return self:SafeExecute(function(res)
        return GetDisplayName(res), res.SlotName or "Unknown"
    end, resource)
end

return ResourceHelper
