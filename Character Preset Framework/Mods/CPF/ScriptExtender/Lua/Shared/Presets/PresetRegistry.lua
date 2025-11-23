---@class PresetRegistry
--- Manages registration and retrieval of character presets
PresetRegistry = {}
PresetRegistry._presets = {}

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
    if PresetRegistry._presets[preset._id] then
        CPFWarn(1, string.format("Preset with ID '%s' already registered. Overwriting.", preset._id))
    end

    PresetRegistry._presets[preset._id] = preset
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

    if not PresetRegistry._presets[id] then
        return false, "Preset with ID '" .. id .. "' not found"
    end

    PresetRegistry._presets[id] = nil
    CPFPrint(2, string.format("Unregistered preset: '%s' (ID: %s)", PresetRegistry._presets[id].Name, id))
    return true, nil
end

--- Gets a preset by ID
---@param id string The preset ID
---@return Preset? preset The preset or nil if not found
function PresetRegistry.Get(id)
    return PresetRegistry._presets[id]
end

--- Gets all registered presets
---@return table<string, Preset> presets Map of preset IDs to preset objects
function PresetRegistry.GetAll()
    return PresetRegistry._presets
end

--- Gets all presets as an array
---@return Preset[] presets Array of all registered presets
function PresetRegistry.GetAllAsArray()
    local presets = {}
    for _, preset in pairs(PresetRegistry._presets) do
        table.insert(presets, preset)
    end
    return presets
end

--- Clears all registered presets (useful for testing)
function PresetRegistry.Clear()
    PresetRegistry._presets = {}
    CPFPrint(2, "Cleared all registered presets")
end

--- Gets the count of registered presets
---@return integer count Number of registered presets
function PresetRegistry.Count()
    local count = 0
    for _ in pairs(PresetRegistry._presets) do
        count = count + 1
    end
    return count
end

return PresetRegistry
