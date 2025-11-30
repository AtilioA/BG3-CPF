-- Centralized localization management for the mod

LocalizationManager = {}

-- ============================================================================
-- LOCALIZATION KEYS
-- All loca string UUIDs should be defined here as constants
-- Format: DESCRIPTIVE_NAME = "uuid-from-loca-xml"
-- ============================================================================
LocalizationManager.Keys = {
    UI_BUTTON_OK = "hf03356ba46684764b32d26ff28d3e709af5a",
    UI_BUTTON_CANCEL = "he43ef9b250584bc2840b8b291c73e4b53cb4",
    UI_BUTTON_YES = "ha639028d9ca54b76a72e88059e3d24acd9a7",
    UI_BUTTON_NO = "h2f7a7913be50404cbbdd9878ee774cca2113",
}

-- ============================================================================
-- CORE FUNCTIONS
-- ============================================================================

--- Get a simple (non-interpolated) localized string
--- @param key string The UUID key from LocalizationManager.Keys
--- @return string The localized string
function LocalizationManager.Get(key)
    local result = Ext.Loca.GetTranslatedString(key)

    -- Error handling: detect missing translations
    if not result or result == "" or result == key then
        Ext.Utils.PrintWarning("[LocalizationManager] Missing translation for key: " .. tostring(key))
        return "[MISSING: " .. tostring(key) .. "]"
    end

    return result
end

--- Get a localized string with positional interpolation
--- Replaces [1], [2], [3], etc. with provided arguments
--- @param key string The UUID key from LocalizationManager.Keys
--- @param ... any Values to interpolate into [1], [2], [3], etc.
--- @return string The localized and interpolated string
function LocalizationManager.Format(key, ...)
    local template = Ext.Loca.GetTranslatedString(key)
    local args = {...}

    -- Error handling: detect missing translations
    if not template or template == "" or template == key then
        Ext.Utils.PrintWarning("[LocalizationManager] Missing translation for key: " .. tostring(key))
        return "[MISSING: " .. tostring(key) .. "]"
    end

    -- Check if we have enough arguments for placeholders
    -- if LocalizationManager.DEBUG_MODE then
    --     local maxPlaceholder = 0
    --     template:gsub("%[(%d+)%]", function(n)
    --         maxPlaceholder = math.max(maxPlaceholder, tonumber(n))
    --     end)

    --     if #args < maxPlaceholder then
    --         Ext.Utils.PrintWarning(string.format(
    --             "[LocalizationManager] Argument mismatch for key %s: template expects %d args, got %d",
    --             tostring(key), maxPlaceholder, #args
    --         ))
    --     end
    -- end

    -- Replace [1], [2], [3], etc. with provided arguments
    local result = template:gsub("%[(%d+)%]", function(n)
        local index = tonumber(n)
        local value = args[index]

        -- Return the value or keep the placeholder if missing
        return value ~= nil and tostring(value) or "[" .. n .. "]"
    end)

    return result
end

--- Get a localized string with plural support
--- Automatically selects singular or plural form based on count
--- @param singularKey string The UUID key for singular form
--- @param pluralKey string The UUID key for plural form
--- @param count number The count to determine singular/plural
--- @param ... any Additional values to interpolate
--- @return string The localized and interpolated string
function LocalizationManager.FormatPlural(singularKey, pluralKey, count, ...)
    local key = count == 1 and singularKey or pluralKey
    return LocalizationManager.Format(key, count, ...)
end

return LocalizationManager
