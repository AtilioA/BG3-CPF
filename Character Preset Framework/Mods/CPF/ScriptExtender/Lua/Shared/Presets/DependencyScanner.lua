---@class DependencyScanner
DependencyScanner = {}

---@class DependencyResource
---@field DisplayName string
---@field ResourceUUID string
---@field SlotName string

---@class ModDependency
---@field ModName string
---@field Resources DependencyResource[]

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
            local resources = Ext.StaticData.GetByModId("CharacterCreationSharedVisual", modUUID)

            if resources then
                for _, resourceUUID in pairs(resources) do
                    resourceToModMap[resourceUUID] = modUUID
                end
            end
        end
    end
end

--- Gets details for a specific resource
---@param resourceUUID string
---@return string displayName, string slotName
function DependencyScanner:GetResourceDetails(resourceUUID)
    local resource = Ext.StaticData.Get(resourceUUID, "CharacterCreationSharedVisual")
    if not resource then return "Unknown", "Unknown" end

    local displayName = ""
    if resource.DisplayName and resource.DisplayName.Get then
        displayName = resource.DisplayName:Get()
    end

    local slotName = resource.SlotName or "Unknown"

    return displayName, slotName
end

--- Scans a character's appearance data for mod dependencies
---@param ccaData CharacterCreationAppearance
---@return table[]
function DependencyScanner:GetDependencies(ccaData)
    self:_BuildReverseLookup()

    local dependencies = {} -- Map<ModUUID, DependencyResource[]>

    local function checkResource(uuid)
        if not uuid or uuid == "" or uuid == "00000000-0000-0000-0000-000000000000" then return end

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
