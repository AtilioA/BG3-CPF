PresetApplication = {}

local function appendAll(target, values)
    if not values then
        return
    end

    for _, value in ipairs(values) do
        table.insert(target, value)
    end
end

local function collectAppliedAttributes(preset)
    local appliedAttributes = {}

    if preset and preset.Data and preset.Data.CCAppearance then
        for key, _ in pairs(preset.Data.CCAppearance) do
            table.insert(appliedAttributes, key)
        end
    end

    return appliedAttributes
end

local function getCharacterName(entity)
    if not entity or not entity.DisplayName or not entity.DisplayName.NameKey then
        return "Unknown"
    end

    return Ext.Loca.GetTranslatedString(entity.DisplayName.NameKey.Handle.Handle)
end

local function buildError(errorCode, errorMessage, extra)
    local result = {
        Success = false,
        ErrorCode = errorCode,
        Error = errorMessage,
        Warnings = {},
        AppliedAttributes = {},
        MissingMods = {},
    }

    if extra then
        for key, value in pairs(extra) do
            result[key] = value
        end
    end

    return result
end

---@param entityUuid string
---@param preset Preset|table
---@param options? {checkAvailability?: boolean, collectWarnings?: boolean, autoEnterMirror?: boolean, logSuccess?: boolean}
---@return table result
function PresetApplication.Apply(entityUuid, preset, options)
    options = options or {}

    if not Ext.IsServer() then
        return buildError("INVALID_CONTEXT", "ApplyPreset must be called from server context")
    end

    if type(entityUuid) ~= "string" then
        return buildError("INVALID_ENTITY_UUID", "Invalid parameter: entityUuid must be a string")
    end

    local valid, validationErr = Preset.Validate(preset)
    if not valid then
        return buildError("INVALID_PRESET", "Invalid preset: " .. tostring(validationErr), {
            ValidationError = validationErr,
        })
    end

    local warnings = {}
    if options.collectWarnings then
        appendAll(warnings, Preset.GetWarnings(preset))
    end

    local missingMods = {}
    if options.checkAvailability then
        missingMods = PresetCompatibility.CheckMods(preset)
        if #missingMods > 0 then
            return buildError(
                "MISSING_DEPENDENCIES",
                "Preset has missing dependencies: " .. table.concat(missingMods, ", "),
                {
                    Warnings = warnings,
                    MissingMods = missingMods,
                }
            )
        end
    end

    local entity = Ext.Entity.Get(entityUuid)
    if not entity then
        return buildError("ENTITY_NOT_FOUND", "Entity not found: " .. entityUuid, {
            Warnings = warnings,
        })
    end

    CCA.ApplyPresetData(entity, preset.Data)

    entity:Replicate("CharacterCreationAppearance")
    entity:Replicate("CharacterCreationStats")

    local appliedAttributes = collectAppliedAttributes(preset)
    local charName = getCharacterName(entity)

    if options.logSuccess then
        CPFPrint(1, string.format("Applied preset '%s' by %s to character %s",
            preset.Name,
            preset.Author,
            charName))
    end

    if options.autoEnterMirror then
        CPFPrint(1, "Auto-entering mirror for " .. charName)
        Osi.StartChangeAppearance(entityUuid)
    end

    return {
        Success = true,
        Error = nil,
        ErrorCode = nil,
        Warnings = warnings,
        AppliedAttributes = appliedAttributes,
        MissingMods = missingMods,
    }
end

return PresetApplication
