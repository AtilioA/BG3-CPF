---@class PresetRecord
---@field preset Preset
---@field indexData? PresetIndexEntry

---@class PresetRegistry
--- Manages registration and retrieval of character presets
PresetRegistry = {}
---@type table<string, PresetRecord>
PresetRegistry._records = {}

--- Registers a new preset
---@param preset Preset The preset to register
---@return boolean success Whether the registration was successful
---@return string? errorMessage Error message if registration failed
function PresetRegistry.Register(preset)
    if not preset then
        return false, "Preset is nil"
    end

    -- Validate the preset before registering
    local valid, err = Preset.Validate(preset)
    if not valid then
        return false, "Invalid preset: " .. tostring(err)
    end

    -- Check if preset already exists
    if PresetRegistry._records[preset._id] then
        CPFWarn(1, string.format("Preset with ID '%s' already registered. Overwriting.", preset._id))
    end

    -- Create wrapper record
    ---@type PresetRecord
    local record = {
        preset = preset,
        indexData = nil
    }

    if PresetIndex then
        record.indexData = PresetIndex.GetEntry(preset._id)
    end

    PresetRegistry._records[preset._id] = record

    CPFPrint(2, string.format("Registered preset: '%s' by %s (ID: %s)", preset.Name, preset.Author, preset._id))
    return true, nil
end

--- Unregisters a preset
---@param id string The preset ID
---@return boolean success Whether the unregistration was successful
---@return string? errorMessage Error message if unregistration failed
function PresetRegistry.Unregister(id)
    if not id then
        return false, "Preset ID is nil"
    end

    if not PresetRegistry._records[id] then
        return false, "Preset with ID '" .. id .. "' not found"
    end

    CPFPrint(2, string.format("Unregistered preset: '%s' (ID: %s)", PresetRegistry._records[id].preset.Name, id))
    PresetRegistry._records[id] = nil
    return true, nil
end

--- Gets a preset record by ID
---@param id string The preset ID
---@return PresetRecord? record The preset record or nil if not found
function PresetRegistry.Get(id)
    return PresetRegistry._records[id]
end

--- Gets all registered preset records
---@return table<string, PresetRecord> records Map of preset IDs to preset records
function PresetRegistry.GetAll()
    return PresetRegistry._records
end

--- Gets all preset records as an array
---@return PresetRecord[] records Array of all registered preset records
function PresetRegistry.GetAllAsArray()
    local records = {}
    for _, record in pairs(PresetRegistry._records) do
        table.insert(records, record)
    end
    return records
end

--- Clears all registered presets (useful for testing)
function PresetRegistry.Clear()
    PresetRegistry._records = {}
    CPFPrint(2, "Cleared all registered presets")
end

--- Gets the count of registered presets
---@return integer count Number of registered presets
function PresetRegistry.Count()
    local count = 0
    for _ in pairs(PresetRegistry._records) do
        count = count + 1
    end
    return count
end

--- Updates the index data for a preset (e.g., when hidden status changes)
---@param id string The preset ID
---@return boolean success Whether the update was successful
function PresetRegistry.UpdateIndexData(id)
    local record = PresetRegistry._records[id]
    if not record then
        return false
    end

    if not PresetIndex then
        return false
    end

    local indexEntry = PresetIndex.GetEntry(id)
    if indexEntry then
        record.indexData = indexEntry
        return true
    end

    return false
end

return PresetRegistry
