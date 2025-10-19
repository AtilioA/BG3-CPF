---@class PresetData
---@field AdditionalChoices string[]|userdata
---@field Elements string[]|userdata
---@field EyeColor string
---@field HairColor string
---@field SecondEyeColor string
---@field SkinColor string
---@field Visuals string[]|userdata

---@class Preset
---@field _id string
---@field Name string
---@field Author string
---@field Version string
---@field Data PresetData

Preset = {}

--- Generates a unique ID for a preset
---@return string
local function generatePresetId()
    local id = VCFormat:CreateUUID()
    return id
end

--- Creates a new preset from character creation appearance data
---@param name string
---@param author string
---@param version string
---@param ccaData CharacterCreationAppearanceComponent
---@return Preset
function Preset.Create(name, author, version, ccaData)
    local preset = {
        _id = generatePresetId(),
        Name = name,
        Author = author,
        Version = version,
        Data = {
            AdditionalChoices = {},
            Elements = {},
            EyeColor = "",
            HairColor = "",
            SecondEyeColor = "",
            SkinColor = "",
            Visuals = {}
        }
    }

    -- Populate Data from CCA component
    if ccaData then
        if ccaData.AdditionalChoices then
            preset.Data.AdditionalChoices = Table.deepcopy(ccaData.AdditionalChoices)
        end
        if ccaData.Elements then
            preset.Data.Elements = Table.deepcopy(ccaData.Elements)
        end
        if ccaData.EyeColor then
            preset.Data.EyeColor = ccaData.EyeColor
        end
        if ccaData.HairColor then
            preset.Data.HairColor = ccaData.HairColor
        end
        if ccaData.SecondEyeColor then
            preset.Data.SecondEyeColor = ccaData.SecondEyeColor
        end
        if ccaData.SkinColor then
            preset.Data.SkinColor = ccaData.SkinColor
        end
        if ccaData.Visuals then
            preset.Data.Visuals = Table.deepcopy(ccaData.Visuals)
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

    _D(preset)
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
---@param preset table
---@return boolean isValid
---@return string? errorMessage
function Preset.Validate(preset)
    if type(preset) ~= "table" then
        return false, "Preset must be a table"
    end

    -- Check required top-level fields
    if not preset._id or type(preset._id) ~= "string" or preset._id == "" then
        return false, "Missing or invalid '_id' field"
    end

    if not preset.Name or type(preset.Name) ~= "string" or preset.Name == "" then
        return false, "Missing or invalid 'Name' field"
    end

    if not preset.Author or type(preset.Author) ~= "string" then
        return false, "Missing or invalid 'Author' field"
    end

    if not preset.Version or type(preset.Version) ~= "string" then
        return false, "Missing or invalid 'Version' field"
    end

    -- Check Data field
    if not preset.Data or type(preset.Data) ~= "table" then
        return false, "Missing or invalid 'Data' field"
    end

    local data = preset.Data

    -- Validate Data subfields (allow missing but check types if present)
    if data.AdditionalChoices and (type(data.AdditionalChoices) ~= "table" and type(data.AdditionalChoices) ~= "userdata") then
        return false, "Invalid 'Data.AdditionalChoices' field - must be a table"
    end

    if data.Elements and (type(data.Elements) ~= "table" and type(data.Elements) ~= "userdata") then
        return false, "Invalid 'Data.Elements' field - must be a table"
    end

    if data.EyeColor and type(data.EyeColor) ~= "string" then
        return false, "Invalid 'Data.EyeColor' field - must be a string"
    end

    if data.HairColor and type(data.HairColor) ~= "string" then
        return false, "Invalid 'Data.HairColor' field - must be a string"
    end

    if data.SecondEyeColor and type(data.SecondEyeColor) ~= "string" then
        return false, "Invalid 'Data.SecondEyeColor' field - must be a string"
    end

    if data.SkinColor and type(data.SkinColor) ~= "string" then
        return false, "Invalid 'Data.SkinColor' field - must be a string"
    end

    if data.Visuals and (type(data.Visuals) ~= "table" and type(data.Visuals) ~= "userdata") then
        return false, "Invalid 'Data.Visuals' field - must be a table"
    end

    return true, nil
end

--- Converts a preset's Data to a CCA-compatible table
---@param preset Preset
---@return CharacterCreationAppearanceComponent ccaTable
function Preset.ToCCATable(preset)
    CPFPrint(2, "Converting preset to CCA table")
    -- REVIEW: maybe needs deepcopy?
    local ccaTable = {
        AdditionalChoices = preset.Data.AdditionalChoices or {},
        Elements = preset.Data.Elements or {},
        EyeColor = preset.Data.EyeColor or "",
        HairColor = preset.Data.HairColor or "",
        SecondEyeColor = preset.Data.SecondEyeColor or "",
        SkinColor = preset.Data.SkinColor or "",
        Visuals = preset.Data.Visuals or {}
    }

    return ccaTable
end

--- Validates and logs any missing or problematic fields in a preset
---@param preset Preset
---@return table warnings -- Array of warning messages
function Preset.GetWarnings(preset)
    local warnings = {}

    if not preset.Data then
        table.insert(warnings, "Missing Data field")
        return warnings
    end

    local data = preset.Data

    -- Check for empty or missing critical fields
    if not data.EyeColor or data.EyeColor == "" then
        table.insert(warnings, "Missing or empty EyeColor")
    end

    if not data.HairColor or data.HairColor == "" then
        table.insert(warnings, "Missing or empty HairColor")
    end

    if not data.SkinColor or data.SkinColor == "" then
        table.insert(warnings, "Missing or empty SkinColor")
    end

    if not data.Visuals or #data.Visuals == 0 then
        table.insert(warnings, "Missing or empty Visuals array")
    end

    if not data.Elements or #data.Elements == 0 then
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
