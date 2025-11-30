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

    -- MessageBox Defaults
    MSG_TITLE_CONFIRMATION = "Confirmation",

    -- State.lua Status Messages
    STATUS_FOUND_PRESETS = "Found [1] preset(s)",
    STATUS_ERROR_REGISTRY_NOT_AVAILABLE = "Error: PresetRegistry not available",
    STATUS_SELECTED_PRESET = "Selected preset: [1]",
    STATUS_ERROR_PLAYER_NOT_FOUND = "Error: Could not find player character",
    STATUS_ERROR_CAPTURE_FAILED = "Error: Could not capture character appearance data",
    STATUS_CAPTURED_DATA = "Captured appearance data from [1]",
    STATUS_ERROR_NO_DATA_TO_SAVE = "Error: No captured data to save",
    STATUS_ERROR_NAME_REQUIRED = "Error: Name is required",
    STATUS_ERROR_PRESET_MODULE_NOT_LOADED = "Error: Preset module not loaded",
    STATUS_ERROR_CREATING_PRESET = "Error creating preset object",
    STATUS_ERROR_DISCOVERY_NOT_AVAILABLE = "Error: PresetDiscovery not available",
    STATUS_PRESET_SAVED = "Preset '[1]' saved",
    STATUS_PRESET_DELETED = "Preset '[1]' deleted",
    STATUS_ERROR_APPLY_NOT_AVAILABLE = "Error: RequestApplyPreset not available",
    STATUS_ERROR_PLAYER_UUID_NOT_FOUND = "Error: Could not get player UUID",
    STATUS_APPLIED_PRESET = "Applied preset '[1]'",
    STATUS_APPLIED_PRESET_WITH_WARNINGS = "Applied preset '[1]' (Warnings: [2])",
    STATUS_FAILED_APPLY_PRESET = "Failed to apply preset",
    STATUS_FAILED_APPLY_PRESET_WITH_WARNINGS = "Failed to apply preset: [1]",
    STATUS_ERROR_IMPORT_EMPTY = "Error: Import buffer is empty",
    STATUS_IMPORT_ERROR = "Import error: [1]",
    STATUS_IMPORTED_PRESET = "Imported '[1]'",

    -- HandleApplyPreset.lua Warnings
    WARN_MISSING_DATA = "Missing CharacterUuid or Preset data",
    WARN_INVALID_PRESET = "Invalid preset: [1]",
    WARN_ENTITY_NOT_FOUND = "Character entity not found",

    -- Window.lua
    UI_BUTTON_REFRESH = "Refresh",
    UI_BUTTON_IMPORT = "Import",
    UI_BUTTON_PRESET_CREATION = "Preset creation",
    UI_HEADER_PRESET_LIST = "Preset list",
    UI_ERROR_UNKNOWN_MODE = "Unknown mode: [1]",

    -- MCMIntegration.lua
    MCM_TAB_PRESET_MANAGER = "Preset manager",
    MCM_MSG_UNHIDDEN_SUCCESS = "All presets unhidden.",
    MCM_MSG_UNHIDDEN_FAILURE = "Failed to unhide presets.",
    MCM_MSG_RESET_SUCCESS = "Preset index correctly reset.\n[1] presets loaded.",
    MCM_MSG_RESET_FAILURE = "Failed to reset presets index.",

    -- CreateMode.lua
    UI_CREATE_HEADER = "Create new preset from selected character",
    UI_LABEL_NAME = "Name",
    UI_LABEL_AUTHOR = "Author",
    UI_LABEL_VERSION = "Version",
    UI_BUTTON_SAVE = "Save",
    UI_HEADER_CAPTURED_ATTRIBUTES = "Captured attributes (preview; for dev purposes):",
    UI_MSG_NO_DATA_CAPTURED = "No data captured.",

    -- ImportMode.lua
    UI_ERROR_SE_VERSION = "You need SE v30 or Devel to use this feature.",
    UI_MSG_PASTE_JSON = "Paste a preset JSON below:",
    UI_BUTTON_IMPORT_NAMED = "Import '[1]'",

    -- ViewMode.lua
    UI_MSG_NO_PRESETS = "No presets available.\nStart by importing or creating a new preset.",
    UI_MSG_SELECT_PRESET = "Click a preset on the left to view details.",
    UI_LABEL_NAME_VALUE = "Name: [1]",
    UI_LABEL_AUTHOR_VALUE = "Author: [1]",
    UI_LABEL_VERSION_VALUE = "Version: [1]",
    UI_LABEL_ID_VALUE = "ID: [1]",
    UI_HEADER_MODS_USED = "Mods used by this preset:\n[1]",
    UI_HEADER_COMPATIBILITY_WARNINGS = "Compatibility warnings:\n[1]",
    UI_WARN_CC_RESTRICTION = "Presets cannot be applied during Character Creation.",
    UI_BUTTON_CANNOT_APPLY = "Cannot apply preset",
    UI_BUTTON_APPLY = "Apply preset",
    UI_WARN_MISSING_MOD = "Missing mod: [1] ([2])",
    UI_MSG_COMPATIBILITY_WARNING =
    "This preset is not fully compatible with your character:\n\n- [1]\n\nThis will cause issues with your character's appearance. Find a compatible preset or change your character with AEE instead.\nAre you sure you want to proceed?",
    UI_TITLE_COMPATIBILITY_WARNING = "Compatibility warning",
    UI_BUTTON_HIDE_PRESET = "Hide preset",
    UI_HEADER_VISUALS = "Visuals:",
    UI_MSG_NO_DATA_AVAILABLE = "No data available.",
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
    local args = { ... }

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

Loca = LocalizationManager

return LocalizationManager
