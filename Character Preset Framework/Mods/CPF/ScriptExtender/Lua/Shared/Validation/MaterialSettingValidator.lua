---@class MaterialSettingValidator
--- Validates CharacterCreationAppearanceMaterialSetting objects
MaterialSettingValidator = {}

--- Validates a CharacterCreationAppearanceMaterialSetting object
---@param materialSetting any
---@param fieldPath? string
---@return boolean isValid
---@return string? errorMessage
function MaterialSettingValidator.Validate(materialSetting, fieldPath)
    fieldPath = fieldPath or "MaterialSetting"

    if materialSetting == nil then
        return true
    end

    if type(materialSetting) ~= "table" and type(materialSetting) ~= "userdata" then
        return false, string.format("%s must be a table or userdata, got %s", fieldPath, type(materialSetting))
    end

    -- If it's userdata, try to convert to table for validation
    local setting = materialSetting
    if type(setting) == "userdata" then
        local success, converted = pcall(function()
            return Ext.Json.Stringify(setting) and Ext.Json.Parse(Ext.Json.Stringify(setting))
        end)
        if not success or type(converted) ~= "table" then
            return false, string.format("%s could not be converted to a valid table", fieldPath)
        end
        setting = converted
    end

    -- Validate UUID fields
    local uuidFields = {"Color", "Material"}
    for _, field in ipairs(uuidFields) do
        local value = setting[field]
        if value ~= nil then
            local isValid, err = UuidValidator.ValidateUuidField(value, fieldPath .. "." .. field)
            if not isValid then
                return false, err
            end
        end
    end

    -- Validate number fields
    local numberFields = {
        {name = "ColorIntensity", type = "number"},
        {name = "GlossyTint", type = "number"},
        {name = "MetallicTint", type = "number"}
    }

    for _, field in ipairs(numberFields) do
        local value = setting[field.name]
        if value ~= nil and type(value) ~= field.type then
            return false, string.format("%s.%s must be a %s, got %s",
                fieldPath, field.name, field.type, type(value))
        end
    end

    return true
end

--- Validates an array of CharacterCreationAppearanceMaterialSetting objects
---@param elements any
---@param fieldPath string
---@return boolean isValid
---@return string? errorMessage
function MaterialSettingValidator.ValidateArray(elements, fieldPath)
    if not elements then return true end

    if type(elements) ~= "table" and type(elements) ~= "userdata" then
        return false, string.format("%s must be a table or userdata, got %s", fieldPath, type(elements))
    end

    -- If it's userdata, try to convert to table for validation
    local elementsTable = elements
    if type(elements) == "userdata" then
        local success, converted = pcall(function()
            return Ext.Json.Stringify(elements) and Ext.Json.Parse(Ext.Json.Stringify(elements))
        end)
        if not success or type(converted) ~= "table" then
            return false, string.format("Could not convert %s to a valid table", fieldPath)
        end
        elementsTable = converted
    end

    for i, element in ipairs(elementsTable) do
        local isValid, err = MaterialSettingValidator.Validate(element, string.format("%s[%d]", fieldPath, i))
        if not isValid then
            return false, err
        end
    end

    return true
end

return MaterialSettingValidator
