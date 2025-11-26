local rx = Ext.Require("Lib/reactivex/_init.lua")

local STATUS_MESSAGE_TIMEOUT = 5000

local State = {
    ViewMode = rx.BehaviorSubject.Create("VIEW"),
    SelectedPreset = rx.BehaviorSubject.Create(nil),
    Presets = rx.BehaviorSubject.Create({}),
    StatusMessage = rx.BehaviorSubject.Create(""),
    CapturedData = rx.BehaviorSubject.Create(nil),
    TargetCharacterUUID = nil,

    -- Buffers
    NewPresetData = rx.BehaviorSubject.Create({
        Name = "",
        Author = "",
        Version = "1.0"
    }),
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
        -- self.NewPresetData:OnNext({ Name = "", Author = "", Version = "1.0" })
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

function State:CaptureCharacterData()
    local function captureData(player)
        if not player then
            CPFWarn(0, "Could not find player entity")
            self:SetStatus("Error: Could not find player character")
            return
        end

        -- Store the target UUID for later use (saving)
        if player.Uuid then
            self.TargetCharacterUUID = player.Uuid.EntityUuid
        end

        -- Get the CharacterCreationAppearance component for PREVIEW purposes
        local ccaData = CCA.CopyCCAOrDummy(player)

        if not ccaData then
            CPFWarn(0, "Player entity does not have CharacterCreationAppearance component")
            self:SetStatus("Error: Could not capture character appearance data")
            return
        end

        -- Store the captured data
        self.CapturedData:OnNext(ccaData)

        -- Get character name for display
        local displayName = ""
        if player.DisplayName and player.DisplayName.NameKey then
            displayName = Ext.Loca.GetTranslatedString(player.DisplayName.NameKey.Handle.Handle)
        end

        self:SetMode("CREATE")
        self:SetStatus("Captured appearance data from " .. tostring(displayName))
        CPFPrint(1, "Successfully captured CCA data from player")
    end

    -- Get the client player entity
    if RequestUserInfo then
        RequestUserInfo({
            OnSuccess = function(response)
                local characterUUID = response.CharacterUUID
                local character = Ext.Entity.Get(characterUUID)
                local data = self.NewPresetData:GetValue()
                if response.UserName and response.UserName ~= "" then
                    data.Author = response.UserName
                end
                if response.CharacterName and response.CharacterName ~= "" then
                    data.Name = response.CharacterName
                end

                captureData(character)
                -- Trigger reactive update
                self.NewPresetData:OnNext(data)
                CPFPrint(1, string.format("Populated preset defaults: Author=%s, Name=%s",
                    data.Author, data.Name))
            end,
            OnFailure = function(response)
                CPFWarn(1, "Failed to retrieve user info from server")
            end
        })
    end
end

--- Refreshes CapturedData with TargetCharacterUUID info
--- @return CharacterCreationAppearance|nil
function State:RefreshTargetCharacterData()
    local data = nil
    if not self.TargetCharacterUUID then
        self.TargetCharacterUUID = _C().Uuid.EntityUuid
    end

    if self.TargetCharacterUUID then
        local character = Ext.Entity.Get(self.TargetCharacterUUID)
        if character then
            data = CCA.CopyCCAOrDummy(character)
            -- Update the preview as well (?)
            self.CapturedData:OnNext(data)
        end
    end

    -- Fallback to existing captured data if re-capture failed (e.g. entity gone)
    if not data then
        data = self.CapturedData:GetValue()
    end

    return data
end

function State:SaveNewPreset()
    -- Re-capture data on save to ensure it's up-to-date
    local data = self:RefreshTargetCharacterData()

    if not data then
        self:SetStatus("Error: No captured data to save")
        return
    end

    local presetData = self.NewPresetData:GetValue()
    local name = presetData.Name
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

    local newPreset = Preset.Create(name, presetData.Author, presetData.Version, data)
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

--- Mark a preset as hidden
---@param record PresetRecord
function State:HidePreset(record)
    if not record or not record.preset then return end

    -- TODO: refactor
    -- Use PresetDiscovery to remove (handles both registry and index)
    if not (PresetDiscovery and PresetDiscovery.HideUserPreset) then
        CPFWarn(0, "PresetDiscovery not available")
        self:SetStatus("Error: PresetDiscovery not available")
        return
    end

    local success, err = PresetDiscovery:HideUserPreset(record.preset._id)
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

    if not RequestApplyPreset then
        CPFWarn(0, "RequestApplyPreset not available")
        self:SetStatus("Error: RequestApplyPreset not available")
        return
    end

    -- Get the client player entity
    local player = Ext.Entity.GetAllEntitiesWithComponent("ClientControl")[1]

    if not player then
        CPFWarn(0, "Could not find player entity")
        self:SetStatus("Error: Could not find player character")
        return
    end

    -- Get the player's UUID
    local playerUuid = player.Uuid.EntityUuid
    if not playerUuid then
        CPFWarn(0, "Could not get player UUID")
        self:SetStatus("Error: Could not get player UUID")
        return
    end

    -- Send request to server to apply preset
    RequestApplyPreset(playerUuid, preset, {
        OnSuccess = function(response)
            local msg = "Applied preset '" .. preset.Name .. "'"
            if response.Warnings and #response.Warnings > 0 then
                msg = msg .. " (Warnings: " .. table.concat(response.Warnings, "; ") .. ")"
            end
            self:SetStatus(msg)
            CPFPrint(1, "Successfully applied preset: " .. preset.Name)
        end,
        OnFailure = function(warnings, response)
            local msg = "Failed to apply preset"
            if warnings and #warnings > 0 then
                msg = msg .. ": " .. table.concat(warnings, "; ")
            end
            self:SetStatus(msg)
            CPFWarn(0, "Failed to apply preset: " .. preset.Name)
        end
    })
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
