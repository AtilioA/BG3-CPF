---@class ValidatorRegistry
--- Manages registration and retrieval of field validators
ValidatorRegistry = {}
ValidatorRegistry._validators = {}

--- Registers a new validator for a specific field
---@param fieldName string The name of the field to validate
---@param validator function The validation function (value, fieldPath) -> (boolean, string?)
function ValidatorRegistry.Register(fieldName, validator)
    ValidatorRegistry._validators[fieldName] = validator
end

--- Gets a validator for a specific field
---@param fieldName string The name of the field
---@return function? validator The validator function or nil if not found
function ValidatorRegistry.GetValidator(fieldName)
    return ValidatorRegistry._validators[fieldName]
end

--- Gets all registered validators
---@return table<string, function> validators Map of field names to validator functions
function ValidatorRegistry.GetAllValidators()
    return ValidatorRegistry._validators
end

return ValidatorRegistry
