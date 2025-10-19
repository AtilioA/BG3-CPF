---@class AdditionalChoicesValidator
--- Validates AdditionalChoices arrays in CharacterCreationAppearance
AdditionalChoicesValidator = {}

--- Validates an AdditionalChoices array
---@param choices any
---@param fieldPath string Path to the field for error messages
---@return boolean isValid
---@return string? errorMessage
function AdditionalChoicesValidator.Validate(choices, fieldPath)
    if not choices then return true end
    
    if type(choices) ~= "table" and type(choices) ~= "userdata" then
        return false, string.format("%s must be a table, got %s", fieldPath, type(choices))
    end
    
    -- If it's userdata, try to convert to table for validation
    local choicesTable = choices
    if type(choices) == "userdata" then
        local success, converted = pcall(function() 
            return Ext.Json.Stringify(choices) and Ext.Json.Parse(Ext.Json.Stringify(choices)) 
        end)
        if not success or type(converted) ~= "table" then
            return false, string.format("Could not convert %s to a valid table", fieldPath)
        end
        choicesTable = converted
    end
    
    for i, choice in ipairs(choicesTable) do
        if type(choice) ~= "number" then
            return false, string.format("%s[%d] must be a number, got %s", fieldPath, i, type(choice))
        end
    end
    
    return true
end

return AdditionalChoicesValidator
