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
        local recordsArray = PresetRegistry.GetAllAsArray()

        -- Filter out hidden presets
        local visibleRecords = {}
        for _, record in ipairs(recordsArray) do
            if not (record.indexData and record.indexData.hidden) then
                table.insert(visibleRecords, record)
            end
        end

        self.Presets:OnNext(visibleRecords)
        local count = #visibleRecords
        self:SetStatus(string.format("Found %d preset(s)", count))
        CPFPrint(1, string.format("Refreshed UI with %d preset(s)", count))
    else
        CPFWarn(0, "PresetRegistry not available")
        self.Presets:OnNext({})
        self:SetStatus("Error: PresetRegistry not available")
    end
end

function State:SelectPreset(record)
    self.SelectedPreset:OnNext(record)
    if record and record.preset then
        self:SetStatus("Selected preset: " .. tostring(record.preset.Name))
    end
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

    -- Use PresetDiscovery to save and register (handles both file and index)
    if not (PresetDiscovery and PresetDiscovery.RegisterUserPreset) then
        CPFWarn(0, "PresetDiscovery not available")
        self:SetStatus("Error: PresetDiscovery not available")
        return
    end

    local success, err = PresetDiscovery:RegisterUserPreset(newPreset)
    if not success then
        CPFWarn(0, "Failed to register preset: " .. tostring(err))
        self:SetStatus("Error: " .. tostring(err))
        return
    end

    self:SetStatus("Preset '" .. name .. "' saved")
    self:RefreshPresets()

    -- Select the new preset (need to fetch the record)
    local record = PresetRegistry.Get(newPreset._id)
    if record then
        self:SelectPreset(record)
    end
end

function State:DeletePreset(record)
    if not record or not record.preset then return end

    -- Use PresetDiscovery to remove (handles both registry and index)
    if not (PresetDiscovery and PresetDiscovery.RemoveUserPreset) then
        CPFWarn(0, "PresetDiscovery not available")
        self:SetStatus("Error: PresetDiscovery not available")
        return
    end

    local success, err = PresetDiscovery:RemoveUserPreset(record.preset._id)
    if not success then
        CPFWarn(0, "Failed to remove preset: " .. tostring(err))
        self:SetStatus("Error: " .. tostring(err))
        return
    end

    self:SetStatus("Preset '" .. record.preset.Name .. "' deleted")
    self:RefreshPresets()
    self.SelectedPreset:OnNext(nil)
end

function State:ApplyPreset(record)
    if not record or not record.preset then return end
    local preset = record.preset

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

    local record = PresetRegistry.Get(preset._id)
    if record then
        self:SelectPreset(record)
    end
end

return State
