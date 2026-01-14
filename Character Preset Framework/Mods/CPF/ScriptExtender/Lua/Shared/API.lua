API = {}

--- Retrieves a list of all registered presets.
---@return Preset[] presets List of preset objects
---@return string? error Error message if retrieval failed
function API.GetPresetList()
    if not PresetRegistry then
        return {}, "PresetRegistry not initialized"
    end

    local records = PresetRegistry.GetAllAsArray()
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
