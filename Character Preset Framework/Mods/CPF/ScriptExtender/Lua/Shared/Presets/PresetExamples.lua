--- Example usage and tests for the Preset module
--- This file demonstrates how to use the Preset serialization/deserialization functions

PresetExamples = {}

--- Example: Create a preset from a character entity
---@param entity EntityHandle
---@return Preset|nil
function PresetExamples.CreatePresetFromEntity(entity)
    local ccaData = CCA.CopyCharacterCreationAppearance(entity)
    if not ccaData then
        CPFWarn(0, "Failed to copy CCA data from entity")
        return nil
    end

    local preset = Preset.Create(
        "My Character",
        "PlayerName",
        "1.0",
        ccaData
    )

    return preset
end

--- Example: Export a preset to JSON file
---@param entity EntityHandle
---@param fileName string
function PresetExamples.ExportEntityPreset(entity, fileName)
    local preset = PresetExamples.CreatePresetFromEntity(entity)
    if not preset then
        return
    end

    local filePath = "Presets/" .. fileName .. ".json"
    local success, err = Preset.ExportToFile(preset, filePath)

    if success then
        CPFPrint(0, "Preset exported successfully to: " .. filePath)
    else
        CPFWarn(0, "Failed to export preset: " .. tostring(err))
    end
end

--- Example: Import and apply a preset
---@param filePath string
---@param targetEntity EntityHandle
function PresetExamples.ImportAndApplyPreset(filePath, targetEntity)
    local preset, err = Preset.ImportFromFile(filePath)

    if not preset then
        CPFWarn(0, "Failed to import preset: " .. tostring(err))
        return
    end

    -- Check for warnings
    local warnings = Preset.GetWarnings(preset)
    if #warnings > 0 then
        CPFWarn(0, "Preset has warnings:")
        for _, warning in ipairs(warnings) do
            CPFWarn(0, "  - " .. warning)
        end
    end

    -- Convert to CCA table and apply
    local ccaTable = Preset.ToCCATable(preset)
    CCA.ApplyCCATable(targetEntity, ccaTable)

    CPFPrint(0, "Preset '" .. preset.Name .. "' by " .. preset.Author .. " applied successfully")
end

--- Example: Serialize and deserialize a preset (round-trip test)
---@param entity EntityHandle
---@return boolean success
function PresetExamples.TestRoundTrip(entity)
    -- Create preset from entity
    local originalPreset = PresetExamples.CreatePresetFromEntity(entity)
    if not originalPreset then
        CPFWarn(0, "Failed to create preset")
        return false
    end

    -- Serialize to JSON
    local jsonString, serErr = Preset.Serialize(originalPreset, true)
    if not jsonString then
        CPFWarn(0, "Serialization failed: " .. tostring(serErr))
        return false
    end

    Preset.ExportToFile(originalPreset, "Presets/OriginalPreset.json")

    CPFPrint(0, "Serialized JSON:")
    CPFPrint(0, jsonString)

    -- Deserialize back
    local deserializedPreset, deserErr = Preset.Deserialize(jsonString)
    if not deserializedPreset then
        CPFWarn(0, "Deserialization failed: " .. tostring(deserErr))
        return false
    end

    -- Validate
    local valid, validErr = Preset.Validate(deserializedPreset)
    if not valid then
        CPFWarn(0, "Validation failed: " .. tostring(validErr))
        return false
    end

    CPFPrint(0, "Round-trip test successful!")
    CPFPrint(0, "Preset ID: " .. deserializedPreset._id)
    CPFPrint(0, "Name: " .. deserializedPreset.Name)
    CPFPrint(0, "Author: " .. deserializedPreset.Author)
    CPFPrint(0, "Version: " .. deserializedPreset.Version)

    return true
end

--- Example: Create a sample preset manually (for testing without an entity)
---@return Preset
function PresetExamples.CreateSamplePreset()
    return {
        _id = "5e9e40609e564e25836a82569a81036e48bf",
        Name = "Example Preset",
        Author = "Volitio",
        Version = "1.0",
        Data = {
            AdditionalChoices = {"Choice1", "Choice2"},
            Elements = {"Element1", "Element2"},
            EyeColor = "7eb2db1f-fa6b-4d46-8b1c-9d8a81b07c51",
            HairColor = "a4b2c3d4-e5f6-7890-1234-567890abcdef",
            SecondEyeColor = "",
            SkinColor = "b5c6d7e8-f9a0-1234-5678-90abcdef1234",
            Visuals = {
                "Visual1",
                "Visual2",
                "Visual3"
            }
        }
    }
end

--- Example: Test validation with various invalid presets
function PresetExamples.TestValidation()
    CPFPrint(0, "=== Testing Preset Validation ===")

    -- Test 1: Valid preset
    local validPreset = PresetExamples.CreateSamplePreset()
    local valid, err = Preset.Validate(validPreset)
    CPFPrint(0, "Valid preset: " .. tostring(valid) .. " (expected: true)")

    -- Test 2: Missing _id
    local noId = Table.deepcopy(validPreset)
    noId._id = nil
    valid, err = Preset.Validate(noId)
    CPFPrint(0, "Missing _id: " .. tostring(valid) .. " - " .. tostring(err))

    -- Test 3: Empty Name
    local emptyName = Table.deepcopy(validPreset)
    emptyName.Name = ""
    valid, err = Preset.Validate(emptyName)
    CPFPrint(0, "Empty Name: " .. tostring(valid) .. " - " .. tostring(err))

    -- Test 4: Missing Data
    local noData = Table.deepcopy(validPreset)
    noData.Data = nil
    valid, err = Preset.Validate(noData)
    CPFPrint(0, "Missing Data: " .. tostring(valid) .. " - " .. tostring(err))

    -- Test 5: Invalid Data.Elements type
    local badElements = Table.deepcopy(validPreset)
    badElements.Data.Elements = "not a table"
    valid, err = Preset.Validate(badElements)
    CPFPrint(0, "Invalid Elements type: " .. tostring(valid) .. " - " .. tostring(err))

    CPFPrint(0, "=== Validation Tests Complete ===")
end

--- Example: Test serialization with beautify on/off
function PresetExamples.TestSerializationFormats()
    local preset = PresetExamples.CreateSamplePreset()

    CPFPrint(0, "=== Beautified JSON ===")
    local beautified, _ = Preset.Serialize(preset, true)
    if beautified then
        CPFPrint(0, beautified)
    end

    CPFPrint(0, "\n=== Compact JSON ===")
    local compact, _ = Preset.Serialize(preset, false)
    if compact then
        CPFPrint(0, compact)
    end
end
