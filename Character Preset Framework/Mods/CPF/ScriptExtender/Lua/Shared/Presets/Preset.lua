-- TODO: missing info:
-- Voice? CCCharacterDefinition
-- TODO: apply to dummy during character creation

---@alias CCAData CharacterCreationAppearance

---@class CCStats
---@field BodyShape integer
---@field BodyType integer
---@field Race string
---@field SubRace string

---@class PresetData
---@field CCStats CCStats
---@field CCAppearance CCAData

---@class Preset
---@field _id string
---@field SchemaVersion string
---@field Name string
---@field Author string
---@field Version string
---@field Data PresetData
---@field Dependencies ModDependency[]

Preset = {}

--- Generates a unique ID for a preset
---@return string
local function generatePresetId()
    return VCFormat:CreateUUID()
end

--- Extracts unified preset data (Stats + Appearance) from an entity
---@param entity EntityHandle
---@return PresetData|nil
function Preset.ExtractData(entity)
    if not entity then return nil end

    local ccaData = CCA.CopyCCAOrDummy(entity)
    if not ccaData then return nil end

    local stats = entity.CharacterCreationStats
    local ccStats = nil
    if stats then
        ccStats = {
            BodyShape = stats.BodyShape,
            BodyType = stats.BodyType,
            Race = stats.Race,
            SubRace = stats.SubRace
        }
    end

    if not ccStats then return nil end

    ---@type PresetData
    return {
        CCStats = ccStats,
        CCAppearance = ccaData
    }
end

--- Creates a new preset from unified character data
---@param name string
---@param author string
---@param version string
---@param unifiedData PresetData
---@return Preset
function Preset.Create(name, author, version, unifiedData)
    ---@type Preset
    local preset = {
        _id = generatePresetId(),
        Name = name,
        Author = author,
        Version = version,
        SchemaVersion = Constants.PRESET_SCHEMA,
        Data = {
            CCStats = {
                BodyShape = 0,
                BodyType = 0,
                Race = "",
                SubRace = ""
            },
            CCAppearance = {
                AccessorySet = "",
                Icon = "",
                field_98 = "",
                AdditionalChoices = {},
                Elements = {},
                EyeColor = "",
                HairColor = "",
                SecondEyeColor = "",
                SkinColor = "",
                Visuals = {}
            }
        },
        Dependencies = {}
    }

    -- Populate Data from UnifiedData
    if unifiedData then
        -- Stats
        if unifiedData.CCStats then
            preset.Data.CCStats = Table.deepcopy(unifiedData.CCStats)
        end

        -- Appearance
        local ccaData = unifiedData.CCAppearance
        if ccaData then
            if ccaData.AdditionalChoices then
                preset.Data.CCAppearance.AdditionalChoices = Table.deepcopy(ccaData.AdditionalChoices)
            end
            if ccaData.Elements then
                preset.Data.CCAppearance.Elements = Table.deepcopy(ccaData.Elements)
            end
            if ccaData.EyeColor then
                preset.Data.CCAppearance.EyeColor = ccaData.EyeColor
            end
            if ccaData.HairColor then
                preset.Data.CCAppearance.HairColor = ccaData.HairColor
            end
            if ccaData.SecondEyeColor then
                preset.Data.CCAppearance.SecondEyeColor = ccaData.SecondEyeColor
            end
            if ccaData.SkinColor then
                preset.Data.CCAppearance.SkinColor = ccaData.SkinColor
            end
            if ccaData.Visuals then
                preset.Data.CCAppearance.Visuals = Table.deepcopy(ccaData.Visuals)
            end

            -- Calculate dependencies based on appearance data
            preset.Dependencies = DependencyScanner:GetDependencies(ccaData)
        end
    end

    return preset
end

--- Serializes a preset to JSON string
---@param preset Preset
---@param beautify? boolean -- Default: true
---@return string? jsonString -- Returns nil on error
---@return string? errorMessage
function Preset.Serialize(preset, beautify)
    if beautify == nil then
        beautify = true
    end

    -- Validate preset structure before serialization
    local valid, err = Preset.Validate(preset)
    if not valid then
        return nil, "Validation failed: " .. err
    end

    local success, result = pcall(function()
        return Ext.Json.Stringify(preset, {
            Beautify = beautify,
            StringifyInternalTypes = false,
            IterateUserdata = false,
            AvoidRecursion = true,
            MaxDepth = 64,
            LimitDepth = 64,
            LimitArrayElements = 1000
        })
    end)

    if success then
        return result, nil
    else
        return nil, "Serialization error: " .. tostring(result)
    end
end

--- Deserializes a JSON string to a preset object
---@param jsonString string
---@return Preset|nil preset -- Returns nil on error
---@return string? errorMessage
function Preset.Deserialize(jsonString)
    if not jsonString or jsonString == "" then
        return nil, "Empty JSON string"
    end

    local success, result = pcall(function()
        return Ext.Json.Parse(jsonString)
    end)

    if not success then
        return nil, "Parse error: " .. tostring(result)
    end

    -- Validate the parsed preset
    local valid, err = Preset.Validate(result)
    if not valid then
        return nil, "Validation failed: " .. err
    end

    ---@cast result Preset
    return result, nil
end

--- Validates a preset object structure
---@param preset Preset|table
---@return boolean isValid
---@return string? errorMessage
function Preset.Validate(preset)
    return PresetValidator.Validate(preset)
end

--- Converts a preset's Data to a CCA-compatible table
---@param preset Preset
---@return CharacterCreationAppearance|nil ccaTable
function Preset.ToCCATable(preset)
    CPFPrint(2, "Converting preset to CCA table")
    ---@type CCAData
    if not preset or not preset.Data or not preset.Data.CCAppearance then
        CPFWarn(0, "Invalid preset data")
        return nil
    end

    local sourceData = preset.Data.CCAppearance

    local ccaTable = {
        AccessorySet = "",
        Icon = "",
        field_98 = "",
        AdditionalChoices = sourceData.AdditionalChoices or {},
        Elements = sourceData.Elements or {},
        EyeColor = sourceData.EyeColor or "",
        HairColor = sourceData.HairColor or "",
        SecondEyeColor = sourceData.SecondEyeColor or "",
        SkinColor = sourceData.SkinColor or "",
        Visuals = sourceData.Visuals or {}
    }

    return ccaTable
end

--- Validates and logs any missing or problematic fields in a preset
---@param preset Preset
---@return table warnings -- Array of warning messages
function Preset.GetWarnings(preset)
    local warnings = {}

    if not preset or not preset.Data or not preset.Data.CCAppearance or not preset.Data.CCStats then
        table.insert(warnings, "Missing Data field or CCAppearance or CCStats")
        return warnings
    end

    ---@type CCAData
    local appearanceData = preset.Data.CCAppearance
    local statsData = preset.Data.CCStats

    -- Check Stats
    if statsData then
        if not statsData.Race or statsData.Race == "" then
            table.insert(warnings, "Missing or empty Race")
        end
        if not statsData.BodyType then
            table.insert(warnings, "Missing BodyType")
        end
        if not statsData.BodyShape then
            table.insert(warnings, "Missing BodyShape")
        end
    end

    -- Check Appearance
    if not appearanceData.EyeColor or appearanceData.EyeColor == "" then
        table.insert(warnings, "Missing or empty EyeColor")
    end

    if not appearanceData.HairColor or appearanceData.HairColor == "" then
        table.insert(warnings, "Missing or empty HairColor")
    end

    if not appearanceData.SkinColor or appearanceData.SkinColor == "" then
        table.insert(warnings, "Missing or empty SkinColor")
    end

    if not appearanceData.Visuals or #appearanceData.Visuals == 0 then
        table.insert(warnings, "Missing or empty Visuals array")
    end

    if not appearanceData.Elements or #appearanceData.Elements == 0 then
        table.insert(warnings, "Missing or empty Elements array")
    end

    return warnings
end

--- Exports a preset to a file
---@param preset Preset
---@param filePath string
---@return boolean success
---@return string? errorMessage
function Preset.ExportToFile(preset, filePath)
    local jsonString, err = Preset.Serialize(preset, true)
    if not jsonString then
        return false, err
    end

    local success, writeErr = pcall(function()
        Ext.IO.SaveFile(filePath, jsonString)
    end)

    if success then
        return true, nil
    else
        return false, "File write error: " .. tostring(writeErr)
    end
end

--- Imports a preset from a file
---@param filePath string
---@return Preset|nil preset
---@return string? errorMessage
function Preset.ImportFromFile(filePath)
    local success, content = pcall(function()
        return Ext.IO.LoadFile(filePath)
    end)

    if not success then
        return nil, "File read error: " .. tostring(content)
    end

    if not content or content == "" then
        return nil, "File is empty or could not be read"
    end

    return Preset.Deserialize(content)
end
