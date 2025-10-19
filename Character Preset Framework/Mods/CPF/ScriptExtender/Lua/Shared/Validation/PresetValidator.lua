---@class PresetValidator
--- Coordinates validation of preset objects by delegating to registered validators
PresetValidator = {}

--- Validates a preset object structure
---@param preset any
---@return boolean isValid
---@return string? errorMessage
function PresetValidator.Validate(preset)
    -- Type checking
    if type(preset) ~= "table" then
        return false, "Preset must be a table"
    end

    -- Check required top-level fields
    local requiredFields = {
        {name = "_id", type = "string", allowEmpty = false},
        {name = "Name", type = "string", allowEmpty = false},
        {name = "Author", type = "string", allowEmpty = true},
        {name = "Version", type = "string", allowEmpty = false},
        {name = "Data", type = "table", allowEmpty = false}
    }

    -- Validate top-level structure
    local isValid, err = PresetValidator.ValidateTopLevel(preset, requiredFields)
    if not isValid then
        return false, err
    end

    -- Delegate to specialized validators for the Data section
    return PresetValidator.ValidateData(preset.Data)
end

--- Validates top-level preset fields
---@param preset table
---@param requiredFields table[]
---@return boolean isValid
---@return string? errorMessage
function PresetValidator.ValidateTopLevel(preset, requiredFields)
    for _, field in ipairs(requiredFields) do
        local value = preset[field.name]
        local valueType = type(value)

        if value == nil then
            return false, string.format("Missing required field: '%s'", field.name)
        end

        -- Handle userdata that should be treated as tables
        if valueType == "userdata" and field.type == "table" then
            local success = pcall(function() return Ext.Json.Stringify(value) and true end)
            if not success then
                return false, string.format("Field '%s' could not be converted to a table", field.name)
            end
        elseif valueType ~= field.type then
            return false, string.format("Field '%s' must be of type '%s', got '%s'",
                field.name, field.type, valueType)
        end

        if not field.allowEmpty and value == "" then
            return false, string.format("Field '%s' cannot be empty", field.name)
        end
    end

    return true
end

--- Validates the Data section of a preset using registered validators
---@param data table
---@return boolean isValid
---@return string? errorMessage
function PresetValidator.ValidateData(data)
    if not data then
        return false, "Preset.Data cannot be nil"
    end

    -- Validate UUID fields
    local uuidFields = {
        {name = "EyeColor", required = false},
        {name = "HairColor", required = false},
        {name = "SecondEyeColor", required = false},
        {name = "SkinColor", required = false},
        {name = "AccessorySet", required = false},
        {name = "Icon", required = false},
        {name = "field_98", required = false}
    }

    for _, field in ipairs(uuidFields) do
        local value = data[field.name]
        if value ~= nil then
            local isValid, err = UuidValidator.ValidateUuidField(value, "Data." .. field.name, true)
            if not isValid then
                return false, err
            end
        elseif field.required then
            return false, string.format("Missing required field: 'Data.%s'", field.name)
        end
    end

    -- Use registered validators for other fields
    for fieldName, validator in pairs(ValidatorRegistry.GetAllValidators()) do
        if data[fieldName] ~= nil then
            local isValid, err = validator(data[fieldName], "Data." .. fieldName)
            if not isValid then
                return false, err
            end
        end
    end

    return true
end

return PresetValidator
