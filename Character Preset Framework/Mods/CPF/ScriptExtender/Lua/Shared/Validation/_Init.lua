-- Load all validators
RequireFiles("Shared/Validation/", {
    "UuidValidator",
    "MaterialSettingValidator",
    "AdditionalChoicesValidator",
    "ValidatorRegistry",
    "PresetValidator",
})

-- Register field validators
ValidatorRegistry.Register("AdditionalChoices", AdditionalChoicesValidator.Validate)
ValidatorRegistry.Register("Elements", MaterialSettingValidator.ValidateArray)
ValidatorRegistry.Register("Visuals", UuidValidator.ValidateUuidArray)
