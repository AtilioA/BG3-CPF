---@class ValueSerializer
ValueSerializer = {}

--- Serializers table - maps data types to serializer functions
---@type table<string, fun(value: any): string>
local serializers = {}

--- Serializer for Race UUIDs
---@param uuid string
---@return string
local function serializeRace(uuid)
    if not uuid or uuid == "" then
        return "None"
    end

    local success, race = pcall(function()
        return Ext.StaticData.Get(uuid, "Race")
    end)

    if success and race and race.DisplayName then
        local displayName = race.DisplayName:Get()
        if displayName and displayName ~= "" then
            return displayName
        end
    end

    -- Fallback to UUID
    return tostring(uuid)
end

--- Serializer for Subrace UUIDs (same as Race)
---@param uuid string
---@return string
local function serializeSubrace(uuid)
    return serializeRace(uuid)
end

--- Serializer for BodyShape integers
---@param value integer
---@return string
local function serializeBodyShape(value)
    local bodyShapes = {
        [0] = "Medium",
        [1] = "Strong"
    }

    return bodyShapes[value] or tostring(value)
end

--- Serializer for BodyType integers
---@param value integer
---@return string
local function serializeBodyType(value)
    local bodyTypes = {
        [0] = "Male",
        [1] = "Female"
    }

    return bodyTypes[value] or tostring(value)
end

--- Serializer for CharacterCreationAccessorySet UUIDs
---@param uuid string
---@return string
local function serializeAccessorySet(uuid)
    if not uuid or uuid == "" then
        return "None"
    end

    local success, accessorySet = pcall(function()
        return Ext.StaticData.Get(uuid, "CharacterCreationAccessorySet")
    end)

    if success and accessorySet and accessorySet.DisplayName then
        local displayName = accessorySet.DisplayName:Get()
        if displayName and displayName ~= "" then
            return displayName
        end
    end

    return tostring(uuid)
end

--- Serializer for CharacterCreationAppearanceMaterial UUIDs
---@param uuid string
---@return string
local function serializeAppearanceMaterial(uuid)
    if not uuid or uuid == "" then
        return "None"
    end

    local success, material = pcall(function()
        return Ext.StaticData.Get(uuid, "CharacterCreationAppearanceMaterial")
    end)

    if success and material then
        -- Try DisplayName first
        if material.DisplayName then
            local displayName = material.DisplayName:Get()
            if displayName and displayName ~= "" then
                return displayName
            end
        end

        -- Fallback to Name field
        if material.Name and material.Name ~= "" then
            return material.Name
        end
    end

    return tostring(uuid)
end

--- Serializer for CharacterCreationEyeColor UUIDs
---@param uuid string
---@return string
local function serializeEyeColor(uuid)
    if not uuid or uuid == "" then
        return "None"
    end

    local success, eyeColor = pcall(function()
        return Ext.StaticData.Get(uuid, "CharacterCreationEyeColor")
    end)

    if success and eyeColor and eyeColor.DisplayName then
        local displayName = eyeColor.DisplayName:Get()
        if displayName and displayName ~= "" then
            return displayName
        end
    end

    return tostring(uuid)
end

--- Serializer for CharacterCreationHairColor UUIDs
---@param uuid string
---@return string
local function serializeHairColor(uuid)
    if not uuid or uuid == "" then
        return "None"
    end

    local success, hairColor = pcall(function()
        return Ext.StaticData.Get(uuid, "CharacterCreationHairColor")
    end)

    if success and hairColor and hairColor.DisplayName then
        local displayName = hairColor.DisplayName:Get()
        if displayName and displayName ~= "" then
            return displayName
        end
    end

    return tostring(uuid)
end

--- Serializer for CharacterCreationSkinColor UUIDs
---@param uuid string
---@return string
local function serializeSkinColor(uuid)
    if not uuid or uuid == "" then
        return "None"
    end

    local success, skinColor = pcall(function()
        return Ext.StaticData.Get(uuid, "CharacterCreationSkinColor")
    end)

    if success and skinColor and skinColor.DisplayName then
        local displayName = skinColor.DisplayName:Get()
        if displayName and displayName ~= "" then
            return displayName
        end
    end

    return tostring(uuid)
end

--- Serializer stub for CharacterCreationSharedVisual UUIDs
---@param uuid string
---@return string
local function serializeSharedVisual(uuid)
    -- TODO: Implement when proper serialization strategy is determined
    return tostring(uuid)
end

--- Serializer stub for CharacterCreationAppearanceVisual UUIDs
---@param uuid string
---@return string
local function serializeAppearanceVisual(uuid)
    -- TODO: Implement when proper serialization strategy is determined
    return tostring(uuid)
end

--- Default serializer fallback
---@param value any
---@return string
local function serializeDefault(value)
    return tostring(value)
end

-- Register all serializers
serializers["Race"] = serializeRace
serializers["Subrace"] = serializeSubrace
serializers["BodyShape"] = serializeBodyShape
serializers["BodyType"] = serializeBodyType
serializers["CharacterCreationAccessorySet"] = serializeAccessorySet
serializers["CharacterCreationAppearanceMaterial"] = serializeAppearanceMaterial
serializers["CharacterCreationEyeColor"] = serializeEyeColor
serializers["CharacterCreationHairColor"] = serializeHairColor
serializers["CharacterCreationSkinColor"] = serializeSkinColor
serializers["CharacterCreationSharedVisual"] = serializeSharedVisual
serializers["CharacterCreationAppearanceVisual"] = serializeAppearanceVisual

--- Serializes a value to a human-readable string
---@param value any The value to serialize
---@param dataType string The type of data (e.g., "Race", "BodyShape", "CharacterCreationEyeColor")
---@return string Human-readable string representation
function ValueSerializer.Serialize(value, dataType)
    if not value then
        return "None"
    end

    local serializer = serializers[dataType]
    if serializer then
        return serializer(value)
    end

    -- Fallback to default serializer
    return serializeDefault(value)
end

return ValueSerializer
