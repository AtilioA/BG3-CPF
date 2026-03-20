API = {}

API._registryLoadAttempted = false
API._lastRegistryTableRef = nil

--- Ensures the preset registry is hydrated in the current Lua context.
--- This is required for server-side API calls, since discovery is normally triggered by client UI init.
---@return boolean success
---@return string? error
function API.EnsurePresetRegistryLoaded()
    if not PresetRegistry then
        return false, "PresetRegistry not initialized"
    end

    local recordsTable = PresetRegistry.GetAll()
    if API._lastRegistryTableRef ~= recordsTable then
        API._lastRegistryTableRef = recordsTable
        API._registryLoadAttempted = false
    end

    if PresetRegistry.Count() > 0 then
        API._registryLoadAttempted = true
        return true, nil
    end

    if API._registryLoadAttempted then
        return true, nil
    end

    if not PresetDiscovery or not PresetDiscovery.LoadPresets then
        return false, "PresetDiscovery not initialized"
    end

    API._registryLoadAttempted = true
    local loadedCount = PresetDiscovery:LoadPresets()
    CPFPrint(1, string.format("API.EnsurePresetRegistryLoaded: discovered %d preset(s)", loadedCount or 0))
    return true, nil
end

--- Retrieves a list of registered presets, optionally filtered.
---@param filters? PresetFilter Optional filters (Race, BodyType, BodyShape)
---@return Preset[] presets List of matching preset objects
---@return string? error Error message if retrieval failed
function API.GetPresetList(filters)
    local loaded, loadErr = API.EnsurePresetRegistryLoaded()
    if not loaded then
        return {}, loadErr or "Failed to load presets"
    end

    local records = PresetRegistry.GetFiltered(filters)
    local presets = {}

    for _, record in ipairs(records) do
        if record and record.preset then
            table.insert(presets, record.preset)
        end
    end

    return presets, nil
end

---@param raceName string
---@return string
local function normalizeRaceBucketName(raceName)
    local normalized = string.upper(raceName)
    normalized = string.gsub(normalized, "[^A-Z]", "")

    local aliases = {
        HALFELF = "HALFELF",
        HALFORC = "HALFORC",
    }

    return aliases[normalized] or normalized
end

---@class AvailablePresetsResult
---@field Ok boolean
---@field Reason "MATCHED"|"NO_MATCH"|"INVALID_INPUT"|"REGISTRY_LOAD_FAILED"|"ENTITY_NOT_FOUND"|"STATS_NOT_FOUND"|"RACE_NOT_FOUND"|"RACE_DATA_NOT_FOUND"
---@field Presets Preset[]
---@field Error string|nil
---@field BucketKey string|nil

---@param ok boolean
---@param reason string
---@param presets Preset[]
---@param errorMessage string|nil
---@param bucketKey string|nil
---@return AvailablePresetsResult
local function buildAvailablePresetsResult(ok, reason, presets, errorMessage, bucketKey)
    return {
        Ok = ok,
        Reason = reason,
        Presets = presets or {},
        Error = errorMessage,
        BucketKey = bucketKey,
    }
end

--- Retrieves available presets for a character by matching its template bucket.
--- Bucket format: <RACE>_<MALE|FEMALE|STRONG_MALE|STRONG_FEMALE>
---@param characterGuid string Character entity GUID/UUID
---@return AvailablePresetsResult result
function API.GetAvailablePresetsForCharacter(characterGuid)
    if type(characterGuid) ~= "string" then
        return buildAvailablePresetsResult(
            false,
            "INVALID_INPUT",
            {},
            "Invalid parameter: characterGuid must be a string",
            nil
        )
    end

    local loaded, loadErr = API.EnsurePresetRegistryLoaded()
    if not loaded then
        return buildAvailablePresetsResult(
            false,
            "REGISTRY_LOAD_FAILED",
            {},
            loadErr or "Failed to load presets",
            nil
        )
    end

    local entity = Ext.Entity.Get(characterGuid)
    if not entity then
        return buildAvailablePresetsResult(
            false,
            "ENTITY_NOT_FOUND",
            {},
            "Entity not found: " .. characterGuid,
            nil
        )
    end

    local targetStats = CCA.ResolveCharacterStats(entity)
    if not targetStats then
        return buildAvailablePresetsResult(
            false,
            "STATS_NOT_FOUND",
            {},
            "CharacterCreationStats not found for entity: " .. characterGuid,
            nil
        )
    end

    if not targetStats.Race then
        return buildAvailablePresetsResult(
            false,
            "RACE_NOT_FOUND",
            {},
            "Character race not found for entity: " .. characterGuid,
            nil
        )
    end

    local raceData = Ext.StaticData.Get(targetStats.Race, "Race")
    if not raceData or not raceData.Name then
        return buildAvailablePresetsResult(
            false,
            "RACE_DATA_NOT_FOUND",
            {},
            "Race static data not found for race GUID: " .. tostring(targetStats.Race),
            nil
        )
    end

    local normalizedRaceName = normalizeRaceBucketName(raceData.Name)
    local maleBodyTypeEnum = Ext.Enums and Ext.Enums.BodyType and Ext.Enums.BodyType.Male
    local isMale = (maleBodyTypeEnum and targetStats.BodyType == maleBodyTypeEnum) or (targetStats.BodyType == 0)
    local isStrong = (targetStats.BodyShape == 1)

    local bodySuffix = isMale and "MALE" or "FEMALE"
    if isStrong then
        bodySuffix = "STRONG_" .. bodySuffix
    end

    local bucketKey = normalizedRaceName .. "_" .. bodySuffix
    local buckets = API.GetPresetsByCharacterTemplate(true)
    local presets = buckets[bucketKey]

    if not presets then
        return buildAvailablePresetsResult(true, "NO_MATCH", {}, nil, bucketKey)
    end

    if #presets == 0 then
        return buildAvailablePresetsResult(true, "NO_MATCH", {}, nil, bucketKey)
    end

    return buildAvailablePresetsResult(true, "MATCHED", presets, nil, bucketKey)
end

--- Retrieves a specific preset by its ID.
---@param id string The UUID of the preset to retrieve
---@return Preset? preset The preset object, or nil if not found or invalid
---@return string? error Error message if retrieval failed
function API.GetPreset(id)
    if type(id) ~= "string" then
        return nil, "Invalid parameter: ID must be a string"
    end

    local loaded, loadErr = API.EnsurePresetRegistryLoaded()
    if not loaded then
        return nil, loadErr or "Failed to load presets"
    end

    local record = PresetRegistry.Get(id)
    if not record then
        return nil, "Preset not found with ID: " .. id
    end

    return record.preset, nil
end

--- Retrieves all presets grouped by 32 character template variants (Race + Gender + BodyType)
--- In practice, this is used by Custom Disguise Self Appearance.
---@param onlyAvailable boolean? If true (default), only return presets with all dependencies loaded
---@return table<string, Preset[]> buckets
function API.GetPresetsByCharacterTemplate(onlyAvailable)
    if onlyAvailable == nil then
        onlyAvailable = true
    end

    local RACE_UUID_TO_NAME = {
        ["b6dccbed-30f3-424b-a181-c4540cf38197"] = "TIEFLING",
        ["0eb594cb-8820-4be6-a58d-8be7a1a98fba"] = "HUMAN",
        ["0ab2874d-cfdc-405e-8a97-d37bfbb23c52"] = "DWARF",
        ["45f4ac10-3c89-4fb2-b37d-f973bb9110c0"] = "HALFELF",
        ["f1b3f884-4029-4f0f-b158-1f9fe0ae5a0d"] = "GNOME",
        ["5c39a726-71c8-4748-ba8d-f768b3c11a91"] = "HALFORC",
        ["4f5d1434-5175-4fa9-b7dc-ab24fba37929"] = "DROW",
        ["bdf9b779-002c-4077-b377-8ea7c1faa795"] = "GITHYANKI",
        ["6c038dcb-7eb5-431d-84f8-cecfaf1c0c5a"] = "ELF",
        ["78cd3bcc-1c43-4a2a-aa80-c34322c16a04"] = "HALFLING",
        ["9c61a74a-20df-4119-89c5-d996956b6c66"] = "DRAGONBORN"
    }

    -- Initialize buckets for the 32 variants
    local buckets = {
        TIEFLING_MALE = {},
        TIEFLING_FEMALE = {},
        DROW_MALE = {},
        DROW_FEMALE = {},
        HUMAN_MALE = {},
        HUMAN_FEMALE = {},
        GITHYANKI_MALE = {},
        GITHYANKI_FEMALE = {},
        DWARF_MALE = {},
        DWARF_FEMALE = {},
        ELF_MALE = {},
        ELF_FEMALE = {},
        HALFELF_MALE = {},
        HALFELF_FEMALE = {},
        HALFLING_MALE = {},
        HALFLING_FEMALE = {},
        GNOME_MALE = {},
        GNOME_FEMALE = {},
        DRAGONBORN_MALE = {},
        DRAGONBORN_FEMALE = {},
        HALFORC_MALE = {},
        HALFORC_FEMALE = {},
        -- Strong variants
        HUMAN_STRONG_MALE = {},
        HUMAN_STRONG_FEMALE = {},
        DROW_STRONG_MALE = {},
        DROW_STRONG_FEMALE = {},
        ELF_STRONG_MALE = {},
        ELF_STRONG_FEMALE = {},
        HALFELF_STRONG_MALE = {},
        HALFELF_STRONG_FEMALE = {},
        TIEFLING_STRONG_MALE = {},
        TIEFLING_STRONG_FEMALE = {}
    }

    local loaded, _ = API.EnsurePresetRegistryLoaded()
    if not loaded then
        return buckets
    end

    local records = PresetRegistry.GetAllAsArray()
    for _, record in ipairs(records) do
        local preset = record.preset
        if preset and preset.Data and preset.Data.CCStats then
            -- Skip hidden presets
            if record.indexData and record.indexData.hidden then
                goto continue
            end

            local stats = preset.Data.CCStats
            local raceName = RACE_UUID_TO_NAME[stats.Race]

            if raceName then
                -- Determine Gender (0 = Male, 1 = Female)
                local gender = (stats.BodyType == Ext.Enums.BodyType.Male) and "MALE" or "FEMALE"

                -- Determine Shape (0 = Medium, 1 = Strong)
                local isStrong = (stats.BodyShape == 1)

                -- Construct key for bucket
                local key
                if isStrong then
                    key = string.format("%s_STRONG_%s", raceName, gender)
                else
                    key = string.format("%s_%s", raceName, gender)
                end

                -- Add to bucket if it exists (some races don't have strong variants in our list)
                if buckets[key] then
                    -- Check if preset is available (all dependencies loaded)
                    if not onlyAvailable then
                        table.insert(buckets[key], preset)
                    else
                        local isAvailable, _ = API.CheckPresetAvailable(preset)
                        if isAvailable then
                            table.insert(buckets[key], preset)
                        end
                    end
                end
            end
        end

        ::continue::
    end

    return buckets
end

--- Validates that a preset ID exists in the registry.
---@param uuid GUIDSTRING The preset UUID to validate
---@return boolean valid True if the preset exists
function API.ValidatePresetId(uuid)
    local preset, _ = API.GetPreset(uuid)
    if not preset then
        return false
    end
    return Preset.Validate(preset)
end

--- Checks if a preset has all its dependencies (mods) loaded and available.
---@param preset Preset The preset to check
---@return boolean available True if all dependencies are loaded
---@return string[] missingMods List of missing mod names/UUIDs if not available
function API.CheckPresetAvailable(preset)
    if not preset then
        return false, {}
    end
    local missingMods = PresetCompatibility.CheckMods(preset)
    return #missingMods == 0, missingMods
end

--- Checks if a preset ID has all its dependencies loaded.
---@param presetId string The UUID of the preset to check
---@return boolean available True if preset exists and all dependencies are loaded
function API.IsPresetAvailable(presetId)
    local preset, err = API.GetPreset(presetId)
    if not preset then
        return false
    end
    local available, _ = API.CheckPresetAvailable(preset)
    return available
end

--- Applies a preset to an entity. Must be called from server context.
---@param entityUuid string The UUID of the target entity
---@param presetId string The UUID of the preset to apply
---@param options? {autoEnterMirror?: boolean} Optional apply behavior overrides
---@return boolean success True if the preset was applied
---@return string? error Error message if application failed
function API.ApplyPreset(entityUuid, presetId, options)
    if not Ext.IsServer() then
        return false, "ApplyPreset must be called from server context"
    end

    options = options or {}

    if type(entityUuid) ~= "string" then
        return false, "Invalid parameter: entityUuid must be a string"
    end

    if type(presetId) ~= "string" then
        return false, "Invalid parameter: presetId must be a string"
    end

    local preset, err = API.GetPreset(presetId)
    if not preset then
        return false, err
    end

    local result = PresetApplication.Apply(entityUuid, preset, {
        checkAvailability = true,
        autoEnterMirror = options.autoEnterMirror == true,
    })

    return result.Success, result.Error
end
