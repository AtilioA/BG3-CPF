-- Centralized localization management for the mod

LocalizationManager = {}

-- ============================================================================
-- LOCALIZATION KEYS
-- All loca string UUIDs should be defined here as constants
-- Format: DESCRIPTIVE_NAME = "uuid-from-loca-xml"
-- ============================================================================
LocalizationManager.Keys = {
    UI_BUTTON_OK = "hab1a5f03d22a48abbf63ebd7273b8edd5f1a",
    UI_BUTTON_CANCEL = "hfb0f1f1f85da401585ef720ab6d1ef0ef31d",
    UI_BUTTON_YES = "hee06e0059ca44ccf9b6bb69bf6968d2a3d23",
    UI_BUTTON_NO = "hd31aa4de029b4685b44e81dcaf8f2b0c1c48",

    -- MessageBox Defaults
    MSG_TITLE_CONFIRMATION = "he3112f7c5b0f438bae3e1109d81408192c53",

    -- State.lua Status Messages
    STATUS_FOUND_PRESETS = "h18474c6f79604d669add8acc02bac4e072ec",
    STATUS_ERROR_REGISTRY_NOT_AVAILABLE = "h4351c6200bc6444694c54fbfb0854297a465",
    STATUS_SELECTED_PRESET = "h17d66385df014e799229d1f512a1eca84dc5",
    STATUS_ERROR_PLAYER_NOT_FOUND = "ha7361001a4d64d779db31dfe08cb911a9dae",
    STATUS_ERROR_CAPTURE_FAILED = "h19b6fafe898e435891600946a60cb850a119",
    STATUS_CAPTURED_DATA = "ha83198c86e44496b941eff8ea174111ceffa",
    STATUS_ERROR_NO_DATA_TO_SAVE = "h46324266d5dd4d69bbc02dd2ba9f525166f4",
    STATUS_ERROR_NAME_REQUIRED = "he4bb5b307b574fe789ade55535619f5cf6g6",
    STATUS_ERROR_PRESET_MODULE_NOT_LOADED = "ha36c2bcf0b6f4fcc81a6592a4d62538d1g0b",
    STATUS_ERROR_CREATING_PRESET = "ha75f41d9fa6649bb826edf8b93c56901c4g9",
    STATUS_ERROR_DISCOVERY_NOT_AVAILABLE = "h8b13d31cbbc14264b15a62eb9a353c737d18",
    STATUS_PRESET_SAVED = "hafc884e8f1904e40aeae71edc0702235dbf9",
    STATUS_PRESET_DELETED = "ha816591c0bde42b9871dc371a9a9ed1a29d8",
    STATUS_ERROR_APPLY_NOT_AVAILABLE = "h978a79713fe247c783e857f994ec6c5195cb",
    STATUS_ERROR_PLAYER_UUID_NOT_FOUND = "h3b8299aae0f1475c984bfa77abf9ee0c38f3",
    STATUS_APPLIED_PRESET = "he0a8f474eb6d4167801d0123ab1bda09262c",
    STATUS_APPLIED_PRESET_WITH_WARNINGS = "h8fb25a8e511a4365b884ebfbc8a1dcf8bba2",
    STATUS_FAILED_APPLY_PRESET = "h800b262a6dc14c9ca4ec98a796a09636dg44",
    STATUS_FAILED_APPLY_PRESET_WITH_WARNINGS = "hcd0f6c359c4f4c68885528dd3688003d184a",
    STATUS_ERROR_IMPORT_EMPTY = "h08f455b31e964a2c83e804ed9aae1aa0eee5",
    STATUS_IMPORT_ERROR = "h7b9091979433406ea3859d7d9d9569eadb1b",
    STATUS_IMPORTED_PRESET = "hb863571eb8cb4db68615e3a82e673f774171",

    -- HandleApplyPreset.lua Warnings
    WARN_MISSING_DATA = "h2db4b2e15b2443409523abd9d1e0a07f9aeg",
    WARN_INVALID_PRESET = "h1efead2668c34518b8903140aed8815fbabd",
    WARN_ENTITY_NOT_FOUND = "h94c17ed18d90428aa5bb08df1c91f0304960",

    -- Window.lua
    UI_BUTTON_REFRESH = "h6c51e75d61fc4a4d8ddffd2ca0001860de2b",
    UI_BUTTON_IMPORT = "h80bfb11d4256473097146840ace2cb63g662",
    UI_BUTTON_PRESET_CREATION = "h683bb9e5226843279de8502d325b3cf018g5",
    UI_HEADER_PRESET_LIST = "hc27829ee46184f29ac0eade3a68796ddf8gf",
    UI_ERROR_UNKNOWN_MODE = "h32d901cc74ff475297bbc46ff1c06fe3c6eg",

    -- MCMIntegration.lua
    MCM_TAB_PRESET_MANAGER = "h89d42e98322d4268b2b76dcc0b18ceaae5c6",
    MCM_MSG_UNHIDDEN_SUCCESS = "hc2a1f9d162cf4764941e7e7b09ecbc182301",
    MCM_MSG_UNHIDDEN_FAILURE = "h5bfe58e13875413facf003e39ad3000f5g52",
    MCM_MSG_RESET_SUCCESS = "hf96c5f584ef64d67afd0ea721cc29d74991a",
    MCM_MSG_RESET_FAILURE = "h8ef2d1955abb4433a0dcb4050a0b4bdefab5",

    -- CreateMode.lua
    UI_CREATE_HEADER = "hb9ac2e174c1e48fbb605a7c86f48a42754fd",
    UI_LABEL_NAME = "hc8ef5df3679f4d6fb2b2d64705d5c03f7890",
    UI_LABEL_AUTHOR = "h5d602891c7a54987b1e45504826e276d10e5",
    UI_LABEL_VERSION = "h8cefdfe321f54bcb8e162485c7925cf05985",
    UI_BUTTON_SAVE = "h1c71aabdfd00464c9d96c676a2c0e6cc3egd",
    UI_HEADER_CAPTURED_ATTRIBUTES = "hf88f70878c104b3d993b3a48891c08503ba3",
    UI_MSG_NO_DATA_CAPTURED = "he001c04c8a80412982d5dd4822f02fbb7023",

    -- ImportMode.lua
    UI_ERROR_SE_VERSION = "hb7f9bfae60e44eb082deb2f9beb542aebfec",
    UI_MSG_PASTE_JSON = "hee5043fa5f3d4141acd588509fddf70a2035",
    UI_BUTTON_IMPORT_NAMED = "h67d6534f54124fab86a060570e02a61b1ag1",

    -- ViewMode.lua
    UI_MSG_NO_PRESETS = "he81f58cb726d4abf953da5d69464c75aa38c",
    UI_MSG_SELECT_PRESET = "h30dd1b4e74ca45e8824e30489d6e9aa6ec63",
    UI_LABEL_NAME_VALUE = "h9050a5972dc84d19b0cbb451b5bb4b03520b",
    UI_LABEL_AUTHOR_VALUE = "h66efb8618f534cdc9c230ddae89220a0d516",
    UI_LABEL_VERSION_VALUE = "haadf3be5009346978ee68b60e4b249b16007",
    UI_LABEL_ID_VALUE = "h44f6be68e24249c5aa81f058f6737b41f0e3",
    UI_HEADER_MODS_USED = "hbf8533fc643f4377a89c2baeb9741df9dd3d",
    UI_HEADER_COMPATIBILITY_WARNINGS = "h958763badc08489cb1eb779c2ec82019c1e0",
    UI_WARN_CC_RESTRICTION = "h2cef40af574a4be4b73c66bde9766b6fg59b",
    UI_BUTTON_CANNOT_APPLY = "hd8b91fe7ceaf4ebd974f3556e102f1c75c13",
    UI_BUTTON_APPLY = "h4fefda7199694bc78271c533da7cb00aa653",
    UI_WARN_MISSING_MOD = "h836f1668294f4e6f8967ed01a320f7767g40",
    UI_MSG_COMPATIBILITY_WARNING =
    "hf6f1da3cd40b4119acffc9c6513bd22f7514",
    UI_TITLE_COMPATIBILITY_WARNING = "h2d9f1ea6dff841a984ed22f83974fa24bee3",
    UI_BUTTON_HIDE_PRESET = "h56e4c13b0e464c6094a2fb7d312f814bgc11",
    UI_HEADER_VISUALS = "hef5c19de8f3c4301aa68ac124e119b279c13",
    UI_MSG_NO_DATA_AVAILABLE = "h88848f5c497a493195cd9450325909db6cc1",

    -- DependencyScanner.lua Resource Types
    RESOURCE_SKIN_COLOR = "hc81ba7bcgb2ccg4423ga050g253fd53ce2c9",
    RESOURCE_EYE_COLOUR = "h1203122ag1146g4759ga531g57ccd5ef36da",
    RESOURCE_HAIR_COLOUR = "h6ed36c54g1a3dg4c46g9987gd5882613ae05",
    RESOURCE_MATERIAL = "h959b01c5g0a34g4d08gbf99g854ac742a452",
    RESOURCE_MATERIAL_OVERRIDE = "h18016894a1b44ba9b36f6d4a7aa64e11ee1d",
    RESOURCE_PASSIVE_FEATURE = "h186cae7a51a14c85aebbb6c6dd11671af8ef",
    RESOURCE_PRESET = "h6bf62ca9ded54abb86e73cb6643bb381fb1c",
    RESOURCE_VOICE_LINE = "h81102ec7gef4dg42edg85b5g60d7fb1d13f9",
    RESOURCE_COLOUR_DEFINITION = "hf97df5b78bab40b39c7764d5dc8a84e77a5e",
    RESOURCE_EQUIPMENT_ICON = "hefc36cdda0a84b8590d2ad967c206cac657b",
    RESOURCE_ICON_SETTINGS = "hd95b57162db648b099f1113aa2dce3cf2d7a",
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
