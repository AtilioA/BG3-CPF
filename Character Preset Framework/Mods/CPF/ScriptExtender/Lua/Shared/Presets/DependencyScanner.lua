---@class DependencyScanner
DependencyScanner = {}

---@class DependencyResource
---@field DisplayName string
---@field ResourceUUID string
---@field SlotName string

---@class ModDependency
---@field ModName string
---@field Resources DependencyResource[]

CCResourceTypes = {
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

-- Cache for reverse lookup: ResourceUUID -> ModUUID
local resourceToModMap = {}
local modUUIDToNameMap = {}

--- Builds the reverse lookup map for resources to mods
--- TODO: might need caching or postponing this for very large load orders (1000+ mods)
---@private
function DependencyScanner:_BuildReverseLookup()
    if next(resourceToModMap) ~= nil then return end

    local modManager = Ext.Mod.GetModManager()

    for _, mod in pairs(modManager.AvailableMods) do
        if ModValidation:IsModRelevant(mod) then
            local modUUID = mod.Info.ModuleUUID
            modUUIDToNameMap[modUUID] = mod.Info.Name

            -- Scan all resource types for this mod
            for _, resourceType in ipairs(CCResourceTypes) do
                local resources = Ext.StaticData.GetByModId(resourceType, modUUID)
                if resources then
                    for _, resourceUUID in pairs(resources) do
                        resourceToModMap[resourceUUID] = modUUID
                    end
                end
            end
        end
    end
end

--- Helper to safely get display name
---@param resource any
---@return string
local function GetDisplayName(resource)
    if resource.DisplayName and resource.DisplayName.Get then
        return resource.DisplayName:Get()
    end
    return ""
end

--- Strategy table for extracting resource details
---@type table<string, fun(resource: any): string, string>
local ResourceStrategies = {
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
function DependencyScanner:_SafeExecute(strategy, resource)
    local success, name, slot = pcall(strategy, resource)
    if success then
        return name, slot
    end
    CPFWarn(0, "Failed to get resource details.")
    return "Unknown", "Unknown"
end

--- Gets details for a specific resource
---@param resourceUUID string
---@return string displayName, string slotName
function DependencyScanner:GetResourceDetails(resourceUUID)
    -- Try all resource types to find the resource
    local resource = nil
    local foundType = nil

    for _, resourceType in ipairs(CCResourceTypes) do
        resource = Ext.StaticData.Get(resourceUUID, resourceType)
        if resource then
            foundType = resourceType
            break
        end
    end

    if not resource then return "Unknown", "Unknown" end

    local strategy = ResourceStrategies[foundType]
    if strategy then
        return self:_SafeExecute(strategy, resource)
    end

    -- Fallback strategy
    return self:_SafeExecute(function(res)
        return GetDisplayName(res), res.SlotName or "Unknown"
    end, resource)
end

--- Scans a character's appearance data for mod dependencies
---@param ccaData CharacterCreationAppearance
---@return table[]
function DependencyScanner:GetDependencies(ccaData)
    self:_BuildReverseLookup()

    local dependencies = {} -- Map<ModUUID, DependencyResource[]>

    local function checkResource(uuid)
        if not uuid or uuid == "" or uuid == Constants.NULL_UUID then return end

        local modUUID = resourceToModMap[uuid]
        if modUUID then
            if not dependencies[modUUID] then
                dependencies[modUUID] = {}
            end

            -- Avoid duplicates
            local exists = false
            for _, res in ipairs(dependencies[modUUID]) do
                if res.ResourceUUID == uuid then
                    exists = true
                    break
                end
            end

            if not exists then
                local name, slot = self:GetResourceDetails(uuid)
                table.insert(dependencies[modUUID], {
                    DisplayName = name,
                    ResourceUUID = uuid,
                    SlotName = slot
                })
            end
        end
    end

    -- Scan Visuals
    if ccaData.Visuals then
        for _, visualUUID in ipairs(ccaData.Visuals) do
            checkResource(visualUUID)
        end
    end

    -- Scan Elements (Materials and Colors)
    if ccaData.Elements then
        for _, element in ipairs(ccaData.Elements) do
            checkResource(element.Material)
            checkResource(element.Color)
        end
    end

    -- Scan other fields
    checkResource(ccaData.EyeColor)
    checkResource(ccaData.HairColor)
    checkResource(ccaData.SecondEyeColor)
    checkResource(ccaData.SkinColor)

    -- Convert map to array with new structure
    local result = {}
    for modUUID, resources in pairs(dependencies) do
        local modName = modUUIDToNameMap[modUUID] or "Unknown"
        local entry = {}
        entry[modUUID] = {
            ModName = modName,
            Resources = resources
        }
        table.insert(result, entry)
    end

    return result
end

return DependencyScanner
