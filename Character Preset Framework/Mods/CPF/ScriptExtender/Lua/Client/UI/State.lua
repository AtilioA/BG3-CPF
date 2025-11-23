local rx = Ext.Require("Lib/reactivex/_init.lua")

local STATUS_MESSAGE_TIMEOUT = 5000

local State = {
    ViewMode = rx.BehaviorSubject.Create("VIEW"),
    SelectedPreset = rx.BehaviorSubject.Create(nil),
    Presets = rx.BehaviorSubject.Create({}),
    StatusMessage = rx.BehaviorSubject.Create(""),
    CapturedData = rx.BehaviorSubject.Create(nil),

    -- Buffers
    NewPresetData = {
        Name = "",
        Author = "",
        Version = "1.0"
    },
    ImportBuffer = "",

    _statusSubscription = nil
}

-- Helper to set status
function State:SetStatus(msg)
    self.StatusMessage:OnNext(msg)

    -- Auto-clear logic to avoid clearing new messages
    if self._statusTimerHandle then
        Ext.Timer.Cancel(self._statusTimerHandle)
        self._statusTimerHandle = nil
    end

    if msg ~= "" then
        -- Clear after STATUS_MESSAGE_TIMEOUT using Ext.Timer
        self._statusTimerHandle = Ext.Timer.WaitFor(STATUS_MESSAGE_TIMEOUT, function()
            self._statusTimerHandle = nil
            if self.StatusMessage:GetValue() == msg then
                self.StatusMessage:OnNext("")
            end
        end)
    end
end

-- REFACTOR: make this less brittle for changes to modes
function State:SetMode(mode)
    -- Validate mode
    if not (mode == "VIEW" or mode == "CREATE" or mode == "IMPORT") then
        return
    end

    self.ViewMode:OnNext(mode)

    -- REVIEW: reset buffers when switching modes?
    if mode == "CREATE" then
        -- self.NewPresetData = { Name = "", Author = "", Version = "1.0" }
    elseif mode == "IMPORT" then
        -- self.ImportBuffer = ""
    end
end

function State:RefreshPresets()
    -- Get presets from registry
    if PresetRegistry then
        local presetsArray = PresetRegistry.GetAllAsArray()
        self.Presets:OnNext(presetsArray)
        local count = #presetsArray
        self:SetStatus(string.format("Loaded %d preset(s)", count))
        CPFPrint(1, string.format("Refreshed UI with %d preset(s)", count))
    else
        CPFWarn(0, "PresetRegistry not available")
        self.Presets:OnNext({})
        self:SetStatus("Error: PresetRegistry not available")
    end
end

function State:SelectPreset(preset)
    self.SelectedPreset:OnNext(preset)
    self:SetStatus("Selected preset: " .. tostring(preset.Name))
    self:SetMode("VIEW")
end

function State:CaptureCharacterData(characterName)
    -- TODO: Get actual player data
    local data = {
        Visuals = { "Visual1", "Visual2" },
        Colors = { Skin = "Red", Hair = "Blue" }
    }
    self.CapturedData:OnNext(data)
    self:SetMode("CREATE")
    self:SetStatus("Captured data from " .. tostring(characterName))
end

function State:SaveNewPreset()
    local data = self.CapturedData:GetValue()
    if not data then
        self:SetStatus("Error: No captured data to save")
        return
    end

    local name = self.NewPresetData.Name
    if name == "" then
        self:SetStatus("Error: Name is required")
        return
    end

    -- Use global Preset module
    if not (Preset and Preset.Create) then
        CPFWarn(0, "Preset module not loaded")
        self:SetStatus("Error: Preset module not loaded")
        return
    end

    local newPreset = Preset.Create(name, self.NewPresetData.Author, self.NewPresetData.Version, data)
    if not newPreset then
        CPFWarn(0, "Failed to create preset object")
        self:SetStatus("Error creating preset object")
        return
    end

    -- Save to file
    local filename = "Presets/" .. name .. ".json"
    if not Preset.ExportToFile then
        CPFWarn(0, "Preset.ExportToFile not available")
        self:SetStatus("Error: Preset.ExportToFile not available")
        return
    end

    local success, err = Preset.ExportToFile(newPreset, filename)
    if not success then
        CPFWarn(0, "Failed to save file: " .. tostring(err))
        self:SetStatus("Error saving file: " .. tostring(err))
        return
    end

    -- Register with PresetRegistry
    if PresetRegistry then
        local regSuccess, regErr = PresetRegistry.Register(newPreset)
        if not regSuccess then
            CPFWarn(0, "Failed to register preset: " .. tostring(regErr))
            self:SetStatus("Error registering preset: " .. tostring(regErr))
            return
        end
    end

    self:SetStatus("Preset '" .. name .. "' saved")
    self:RefreshPresets()
    self:SelectPreset(newPreset)
end

function State:DeletePreset(preset)
    if not preset then return end

    self:SetStatus("Preset '" .. preset.Name .. "' deleted (Note: Registry only, file not deleted)")

    -- TODO: update preset index to hide deleted presets
    -- Remove from PresetRegistry
    if PresetRegistry and PresetRegistry._presets and preset._id then
        PresetRegistry._presets[preset._id] = nil
        CPFPrint(1, "Removed preset from registry: " .. preset._id)
    end

    self:RefreshPresets()
    self.SelectedPreset:OnNext(nil)
end

function State:ApplyPreset(preset)
    if not preset then return end

    if not (Preset and Preset.ToCCATable) then
        CPFWarn(0, "Preset module not loaded")
        self:SetStatus("Error: Preset module not loaded")
        return
    end

    -- Check for warnings first
    if Preset.GetWarnings then
        local warnings = Preset.GetWarnings(preset)
        if warnings and #warnings > 0 then
            local msg = "Warnings: " .. table.concat(warnings, "; ")
            self:SetStatus(msg)
        end
    end

    local ccaTable = Preset.ToCCATable(preset)
    -- Find client player entity
    -- local entity = _C()
    -- CCA.ApplyCCATable(entity, ccaTable)

    self:SetStatus("Preset '" .. preset.Name .. "' applied (Mock)")
end

function State:ImportFromBuffer()
    if self.ImportBuffer == "" then return end

    if not Preset or not Preset.Deserialize then
        CPFWarn(0, "Preset module not loaded")
        self:SetStatus("Error: Preset module not loaded")
        return
    end

    local preset, err = Preset.Deserialize(self.ImportBuffer)
    if not preset then
        CPFWarn(0, "Failed to deserialize import buffer: " .. tostring(err))
        self:SetStatus("Import Error: " .. tostring(err))
        return
    end

    -- Register with PresetRegistry
    -- TODO: reduce code duplication
    if PresetRegistry then
        local regSuccess, regErr = PresetRegistry.Register(preset)
        if not regSuccess then
            CPFWarn(0, "Failed to register preset: " .. tostring(regErr))
            self:SetStatus("Import Error: " .. tostring(regErr))
            return
        end
    end

    self:SetStatus("Imported '" .. preset.Name .. "'")
    self:RefreshPresets()
    self:SelectPreset(preset)
end

return State
