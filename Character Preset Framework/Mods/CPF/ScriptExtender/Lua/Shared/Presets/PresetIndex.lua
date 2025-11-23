---@class PresetIndexEntry
---@field filename string Relative path to the preset file
---@field hidden boolean Whether the preset is hidden (deleted)
---@field presetId string The ID of the preset

---@class PresetIndex
---@field IndexFilePath string Path to the index file
PresetIndex = {
    IndexFilePath = "CPF/cpf_presets_index.json"
}

--- Loads the preset index from disk
---@return PresetIndexEntry[] entries List of index entries
function PresetIndex.Load()
    local data, err = JsonLayer:Load(PresetIndex.IndexFilePath)

    if not data then
        -- If file doesn't exist or is invalid, return empty list (reconstruction/first run)
        CPFDebug(2, "Preset index not found or invalid, starting fresh.")
        return {}
    end

    if not Table.IsArray(data) then
        CPFWarn(1, "Preset index is not an array, resetting.")
        return {}
    end

    return data
end

--- Saves the preset index to disk
---@param entries PresetIndexEntry[] List of index entries
---@return boolean success
---@return string? error
function PresetIndex.Save(entries)
    local jsonString = Ext.Json.Stringify(entries, { Beautify = true })
    local success, err = pcall(function()
        Ext.IO.SaveFile(PresetIndex.IndexFilePath, jsonString)
    end)

    if not success then
        CPFWarn(0, "Failed to save preset index: " .. tostring(err))
        return false, tostring(err)
    end

    return true
end

--- Adds or updates an entry in the index
---@param filename string Relative path to the preset file
---@param presetId string The ID of the preset
---@return boolean success
function PresetIndex.AddEntry(filename, presetId)
    local entries = PresetIndex.Load()
    local found = false

    for _, entry in ipairs(entries) do
        if entry.filename == filename then
            entry.hidden = false
            -- Update ID just in case
            entry.presetId = presetId
            found = true
            break
        end
    end

    if not found then
        table.insert(entries, {
            filename = filename,
            hidden = false,
            presetId = presetId
        })
    end

    return PresetIndex.Save(entries)
end

--- Removes (hides) an entry from the index by filename
---@param filename string Relative path to the preset file
---@return boolean success
function PresetIndex.RemoveEntry(filename)
    local entries = PresetIndex.Load()
    local changed = false

    for _, entry in ipairs(entries) do
        if entry.filename == filename and not entry.hidden then
            entry.hidden = true
            changed = true
            break
        end
    end

    if changed then
        return PresetIndex.Save(entries)
    end

    return false
end

--- Removes (hides) an entry from the index by preset ID
---@param presetId string The ID of the preset
---@return boolean success
function PresetIndex.RemoveEntryByPresetId(presetId)
    local entries = PresetIndex.Load()
    local changed = false

    for _, entry in ipairs(entries) do
        if entry.presetId == presetId and not entry.hidden then
            entry.hidden = true
            changed = true
            -- IDs should be unique safe to break.
            break
        end
    end

    if changed then
        return PresetIndex.Save(entries)
    end

    return false
end

return PresetIndex
