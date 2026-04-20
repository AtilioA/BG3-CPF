---@class PresetCompat
PresetCompat = {}

---@param value any
---@return boolean
function PresetCompat.IsLegacyMetallicTintValue(value)
    if type(value) ~= "number" then
        return false
    end

    if value ~= math.floor(value) then
        return false
    end

    return value < 0 or value > 1
end

---@param value number
---@return number|nil
function PresetCompat.UInt32BitsToFloat(value)
    local success, converted = pcall(function()
        return string.unpack("<f", string.pack("<I4", value))
    end)

    if success then
        return converted
    end

    return 0
end

---@param preset table|nil
---@return integer convertedCount
function PresetCompat.NormalizePresetMetallicTint(preset)
    if type(preset) ~= "table" then
        return 0
    end

    local elements = preset.Data and
        preset.Data.CCAppearance and
        preset.Data.CCAppearance.Elements

    if type(elements) ~= "table" then
        return 0
    end

    local convertedCount = 0

    for _, element in ipairs(elements) do
        if type(element) == "table" or type(element) == "userdata" then
            local metallicTint = element.MetallicTint
            if PresetCompat.IsLegacyMetallicTintValue(metallicTint) then
                local converted = PresetCompat.UInt32BitsToFloat(metallicTint)
                if converted ~= nil then
                    element.MetallicTint = converted
                    convertedCount = convertedCount + 1
                end
            end
        end
    end

    return convertedCount
end

return PresetCompat
