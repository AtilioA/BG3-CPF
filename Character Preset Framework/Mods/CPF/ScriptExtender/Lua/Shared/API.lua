API = {}

--- Retrieves a list of registered presets, optionally filtered.
---@param filters? PresetFilter Optional filters (Race, BodyType, BodyShape)
---@return Preset[] presets List of matching preset objects
---@return string? error Error message if retrieval failed
function API.GetPresetList(filters)
    if not PresetRegistry then
        return {}, "PresetRegistry not initialized"
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

--- Retrieves a specific preset by its ID.
---@param id string The UUID of the preset to retrieve
---@return Preset? preset The preset object, or nil if not found or invalid
---@return string? error Error message if retrieval failed
function API.GetPreset(id)
    if type(id) ~= "string" then
        return nil, "Invalid parameter: ID must be a string"
    end

    if not PresetRegistry then
        return nil, "PresetRegistry not initialized"
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

    if not PresetRegistry then
        return buckets
    end

    local records = PresetRegistry.GetAllAsArray()
    for _, record in ipairs(records) do
        local preset = record.preset
        if preset and preset.Data and preset.Data.CCStats then
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
