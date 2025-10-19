---@class UuidValidator
--- Validates UUID strings according to BG3's format (8-4-4-4-12 hex digits)
UuidValidator = {}

--- Checks if a string is a valid UUID
---@param value any
---@return boolean
function UuidValidator.IsValidUuid(value)
    if type(value) ~= "string" then return false end
    -- UUID pattern: 8-4-4-4-12 hex digits
    return string.match(value, "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil
end

--- Validates a field that should be a UUID
---@param value any
---@param fieldPath string Path to the field for error messages
---@param allowEmpty? boolean If true, empty strings are considered valid
---@return boolean isValid
---@return string? errorMessage
function UuidValidator.ValidateUuidField(value, fieldPath, allowEmpty)
    if value == nil or (allowEmpty and value == "") then
        return true
    end
    
    if not UuidValidator.IsValidUuid(value) then
        return false, string.format("Field '%s' must be a valid UUID, got: %s", fieldPath, tostring(value))
    end
    
    return true
end

--- Validates an array of UUIDs
---@param values table Array of values to validate
---@param fieldPath string Path to the field for error messages
---@return boolean isValid
---@return string? errorMessage
function UuidValidator.ValidateUuidArray(values, fieldPath)
    if not values then return true end
    
    if type(values) ~= "table" then
        return false, string.format("Field '%s' must be a table, got: %s", fieldPath, type(values))
    end
    
    for i, value in ipairs(values) do
        local isValid, err = UuidValidator.ValidateUuidField(value, string.format("%s[%d]", fieldPath, i))
        if not isValid then
            return false, err
        end
    end
    
    return true
end

return UuidValidator
