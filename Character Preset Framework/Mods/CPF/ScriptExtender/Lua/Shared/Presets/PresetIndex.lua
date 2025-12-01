---@class PresetIndexEntry
---@field filename string Relative path to the preset file (may be empty for mod presets)
---@field hidden boolean Whether the preset is hidden (deleted)
---@field presetId string The ID of the preset
---@field source string Source of the preset: "user" or "mod"
---@field modName string? Name of the mod (for mod presets)

---@class PresetIndex
---@field IndexFilePath string Path to the index file
PresetIndex = {
    IndexFilePath = "CPF/cpf_presets_index.json"
}

--- Loads the preset index from disk
---@return PresetIndexEntry[] entries List of index entries
function PresetIndex.Load()
    CPFDebug(2, "PresetIndex.Load: Loading from " .. PresetIndex.IndexFilePath)
    local data, err = JsonLayer:Load(PresetIndex.IndexFilePath)

    if not data then
        -- If file doesn't exist or is invalid, return empty list (reconstruction/first run)
        CPFDebug(2, "Preset index not found or invalid, starting fresh.")
        -- Create the empty index file immediately
        PresetIndex.Save({})
        return {}
    end

    if not Table.IsArray(data) and next(data) ~= nil then
        CPFWarn(1, "Preset index is not an array, resetting.")
        return {}
    end

    CPFDebug(2, string.format("PresetIndex.Load: Loaded %d entries", #data))
    return data
end

--- Saves the preset index to disk
---@param entries PresetIndexEntry[] List of index entries
---@return boolean success
---@return string? error
function PresetIndex.Save(entries)
    CPFDebug(2, string.format("PresetIndex.Save: Saving %d entries to %s", #entries, PresetIndex.IndexFilePath))
    local jsonString = Ext.Json.Stringify(entries, { Beautify = true })
    local success, err = pcall(function()
        Ext.IO.SaveFile(PresetIndex.IndexFilePath, jsonString)
    end)

    if not success then
        CPFWarn(0, "Failed to save preset index: " .. tostring(err))
        return false, tostring(err)
    end

    CPFDebug(2, "PresetIndex.Save: Successfully saved index")
    return true
end

--- Adds or updates an entry in the index
---@param filename string Relative path to the preset file (can be empty string for mod presets)
---@param presetId string The ID of the preset
---@param source string Source: Mod Name or "User"
---@return boolean success
function PresetIndex.AddEntry(filename, presetId, source)
    source = source or "user"
    CPFDebug(2,
        string.format("PresetIndex.AddEntry: filename='%s', presetId='%s', source='%s'", filename, presetId, source))
    local entries = PresetIndex.Load()
    local found = false

    -- Look for existing entry by presetId (not filename, since mod presets may not have filenames)
    for _, entry in ipairs(entries) do
        if entry.presetId == presetId then
            entry.hidden = entry.hidden
            entry.filename = filename ~= "" and filename or entry.filename
            -- entry.source = source
            found = true
            CPFDebug(2, "PresetIndex.AddEntry: Updated existing entry")
            break
        end
    end

    if not found then
        local newEntry = {
            filename = filename ~= "" and filename or "",
            hidden = false,
            presetId = presetId,
            source = source
        }
        table.insert(entries, newEntry)
        CPFDebug(1, "PresetIndex.AddEntry: Added new entry")
    end

    local success = PresetIndex.Save(entries)
    CPFDebug(2, string.format("PresetIndex.AddEntry: Save result = %s", tostring(success)))
    return success
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

    return true
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

    return true
end

--- Gets a single entry from the index by preset ID
---@param presetId string The ID of the preset
---@return PresetIndexEntry? entry The index entry or nil if not found
function PresetIndex.GetEntry(presetId)
    local entries = PresetIndex.Load()

    for _, entry in ipairs(entries) do
        if entry.presetId == presetId then
            return entry
        end
    end

    return nil
end

--- Clears the entire preset index
---@return boolean success
function PresetIndex.Clear()
    CPFDebug(1, "PresetIndex.Clear: Clearing all entries")
    return PresetIndex.Save({})
end

--- Sets the hidden state of a single entry from the index by preset ID
---@param presetId string The ID of the preset
---@param hidden boolean Whether the preset should be hidden
---@return boolean success
function PresetIndex.SetHidden(presetId, hidden)
    local entries = PresetIndex.Load()
    local changed = false

    for _, entry in ipairs(entries) do
        if entry.presetId == presetId then
            entry.hidden = hidden
            changed = true
            -- IDs should be unique safe to break.
            break
        end
    end

    if changed then
        return PresetIndex.Save(entries)
    end

    return true
end

--- Unhide all presets in the preset index
---@return boolean success
function PresetIndex.UnhideAll()
    CPFDebug(1, "PresetIndex.UnhideAll: Unhiding all presets")
    local entries = PresetIndex.Load()
    for _, entry in ipairs(entries) do
        entry.hidden = false
    end
    return PresetIndex.Save(entries)
end

return PresetIndex
