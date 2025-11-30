local rx = Ext.Require("Lib/reactivex/_init.lua")

local STATUS_MESSAGE_TIMEOUT = 3000

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
    ImportBuffer = rx.BehaviorSubject.Create(""),

    _statusSubscription = nil
}

local L = LocalizationManager

function State:GetStatusMessageDuration(msg)
    local increase = #msg / 20 * 1000
    return STATUS_MESSAGE_TIMEOUT + increase
end

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
        self._statusTimerHandle = Ext.Timer.WaitFor(self:GetStatusMessageDuration(msg), function()
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
        -- self.ImportBuffer:OnNext("")
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
        self:SetStatus(Loca.Format(Loca.Keys.STATUS_FOUND_PRESETS, count))
        CPFPrint(1, string.format("Refreshed UI with %d preset(s)", count))
    else
        CPFWarn(0, "PresetRegistry not available")
        self.Presets:OnNext({})
        self:SetStatus(Loca.Get(Loca.Keys.STATUS_ERROR_REGISTRY_NOT_AVAILABLE))
    end
end

function State:SelectPreset(record)
    self.SelectedPreset:OnNext(record)
    if record and record.preset then
        self:SetStatus(Loca.Format(Loca.Keys.STATUS_SELECTED_PRESET, record.preset.Name))
    end
    self:SetMode("VIEW")
end

function State:CaptureCharacterData()
    local function captureData(player)
        if not player then
            CPFWarn(0, "Could not find player entity")
            self:SetStatus(Loca.Get(Loca.Keys.STATUS_ERROR_PLAYER_NOT_FOUND))
            return
        end

        -- Store the target UUID for later use (saving)
        if player.Uuid then
            self.TargetCharacterUUID = player.Uuid.EntityUuid
        end

        -- Get the unified data (Stats + Appearance)
        local unifiedData = Preset.ExtractData(player)

        if not unifiedData or not unifiedData.CCAppearance then
            CPFWarn(0, "Player entity does not have CharacterCreationAppearance component")
            self:SetStatus(Loca.Get(Loca.Keys.STATUS_ERROR_CAPTURE_FAILED))
            return
        end

        self.CapturedData:OnNext(unifiedData)


        -- Get character name for display
        local displayName = ""
        if player.DisplayName and player.DisplayName.NameKey then
            displayName = Ext.Loca.GetTranslatedString(player.DisplayName.NameKey.Handle.Handle)
        end

        self:SetMode("CREATE")
        self:SetStatus(Loca.Format(Loca.Keys.STATUS_CAPTURED_DATA, displayName))
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
--- @return PresetData|nil
function State:RefreshTargetCharacterData()
    local data = nil
    if not self.TargetCharacterUUID then
        self.TargetCharacterUUID = _C().Uuid.EntityUuid
    end

    if self.TargetCharacterUUID then
        local character = Ext.Entity.Get(self.TargetCharacterUUID)
        if character then
            data = Preset.ExtractData(character)
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
        self:SetStatus(Loca.Get(Loca.Keys.STATUS_ERROR_NO_DATA_TO_SAVE))
        return
    end

    local presetData = self.NewPresetData:GetValue()
    local name = presetData.Name
    if name == "" then
        self:SetStatus(Loca.Get(Loca.Keys.STATUS_ERROR_NAME_REQUIRED))
        return
    end

    -- Use global Preset module
    if not (Preset and Preset.Create) then
        CPFWarn(0, "Preset module not loaded")
        self:SetStatus(Loca.Get(Loca.Keys.STATUS_ERROR_PRESET_MODULE_NOT_LOADED))
        return
    end

    local newPreset = Preset.Create(name, presetData.Author, presetData.Version, data)
    if not newPreset then
        CPFWarn(0, "Failed to create preset object")
        self:SetStatus(Loca.Get(Loca.Keys.STATUS_ERROR_CREATING_PRESET))
        return
    end

    -- Use PresetDiscovery to save and register (handles both file and index)
    if not (PresetDiscovery and PresetDiscovery.RegisterUserPreset) then
        CPFWarn(0, "PresetDiscovery not available")
        self:SetStatus(Loca.Get(Loca.Keys.STATUS_ERROR_DISCOVERY_NOT_AVAILABLE))
        return
    end

    local success, err = PresetDiscovery:RegisterUserPreset(newPreset)
    if not success then
        CPFWarn(1, "Warning when registering preset: " .. tostring(err))
        self:SetStatus(Loca.Format(Loca.Keys.STATUS_ERROR_REGISTER_PRESET, tostring(err)))
        return
    end

    self:SetStatus(Loca.Format(Loca.Keys.STATUS_PRESET_SAVED, name))
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
        self:SetStatus(Loca.Get(Loca.Keys.STATUS_ERROR_DISCOVERY_NOT_AVAILABLE))
        return
    end

    local success, err = PresetDiscovery:HideUserPreset(record.preset._id)
    if not success then
        CPFWarn(0, "Failed to remove preset: " .. tostring(err))
        self:SetStatus(Loca.Format(Loca.Keys.STATUS_ERROR_HIDE_PRESET, tostring(err)))
        return
    end

    self:SetStatus(Loca.Format(Loca.Keys.STATUS_PRESET_DELETED, record.preset.Name))
    self:RefreshPresets()
    self.SelectedPreset:OnNext(nil)
end

function State:ApplyPreset(record)
    if not record or not record.preset then return end
    local preset = record.preset

    if not RequestApplyPreset then
        CPFWarn(0, "RequestApplyPreset not available")
        self:SetStatus(Loca.Get(Loca.Keys.STATUS_ERROR_APPLY_NOT_AVAILABLE))
        return
    end

    -- Get the client player entity
    local player = Ext.Entity.GetAllEntitiesWithComponent("ClientControl")[1]

    if not player then
        CPFWarn(0, "Could not find player entity")
        self:SetStatus(Loca.Get(Loca.Keys.STATUS_ERROR_PLAYER_NOT_FOUND))
        return
    end

    -- Get the player's UUID
    local playerUuid = player.Uuid.EntityUuid
    if not playerUuid then
        CPFWarn(0, "Could not get player UUID")
        self:SetStatus(Loca.Get(Loca.Keys.STATUS_ERROR_PLAYER_UUID_NOT_FOUND))
        return
    end

    -- Send request to server to apply preset
    RequestApplyPreset(playerUuid, preset, {
        OnSuccess = function(response)
            if response.Warnings and #response.Warnings > 0 then
                self:SetStatus(Loca.Format(Loca.Keys.STATUS_APPLIED_PRESET_WITH_WARNINGS, preset.Name,
                    table.concat(response.Warnings, "; ")))
            else
                self:SetStatus(Loca.Format(Loca.Keys.STATUS_APPLIED_PRESET, preset.Name))
            end
            CPFPrint(1, "Successfully applied preset: " .. preset.Name)
        end,
        OnFailure = function(warnings, response)
            if warnings and #warnings > 0 then
                self:SetStatus(Loca.Format(Loca.Keys.STATUS_FAILED_APPLY_PRESET_WITH_WARNINGS,
                    table.concat(warnings, "; ")))
            else
                self:SetStatus(Loca.Get(Loca.Keys.STATUS_FAILED_APPLY_PRESET))
            end
            CPFWarn(0, "Failed to apply preset: " .. preset.Name)
        end
    })
end

function State:ImportFromBuffer()
    if self.ImportBuffer:GetValue() == "" then
        self:SetStatus(Loca.Get(Loca.Keys.STATUS_ERROR_IMPORT_EMPTY))
        return
    end

    if not Preset or not Preset.Deserialize then
        CPFWarn(0, "Preset module not loaded")
        self:SetStatus(Loca.Get(Loca.Keys.STATUS_ERROR_PRESET_MODULE_NOT_LOADED))
        return
    end

    local success, presetOrError, presetDeserializeError = xpcall(
        function()
            return Preset.Deserialize(self.ImportBuffer:GetValue())
        end,
        function(err)
            return debug.traceback(tostring(err), 2)
        end
    )

    if not success then
        CPFWarn(0, "Import failed: " .. tostring(presetOrError))
        self:SetStatus(Loca.Format(Loca.Keys.STATUS_IMPORT_ERROR, presetOrError))
        return
    end

    -- Handle xpcall result (first return is success boolean)
    if not presetOrError then
        CPFWarn(0, "Failed to parse/validate import buffer: " .. tostring(presetDeserializeError))
        self:SetStatus(Loca.Format(Loca.Keys.STATUS_IMPORT_ERROR, presetDeserializeError))
        return
    end

    -- Deserialize returns (preset, err), so we need to check the actual result
    local actualPreset, validationErr = presetOrError, presetDeserializeError
    if not actualPreset then
        CPFWarn(0, "Failed to deserialize import buffer: " .. tostring(validationErr))
        self:SetStatus(Loca.Format(Loca.Keys.STATUS_IMPORT_ERROR, validationErr))
        return
    end

    -- Use PresetDiscovery to register (handles both registry and index, will refactor later :gladge:)
    if not (PresetDiscovery and PresetDiscovery.RegisterUserPreset) then
        CPFWarn(0, "PresetDiscovery not available")
        self:SetStatus(Loca.Get(Loca.Keys.STATUS_ERROR_DISCOVERY_NOT_AVAILABLE))
        return
    end

    local registrationSuccess, err = PresetDiscovery:RegisterUserPreset(actualPreset)
    if not registrationSuccess then
        CPFWarn(0, "Failed to register imported preset: " .. tostring(err))
        self:SetStatus(Loca.Format(Loca.Keys.STATUS_IMPORT_ERROR, err))
        return
    end

    -- Unhide preset just in case
    PresetIndex.SetHidden(actualPreset._id, false)
    self.ImportBuffer:OnNext("")
    self:SetStatus(Loca.Format(Loca.Keys.STATUS_IMPORTED_PRESET, actualPreset.Name))
    self:RefreshPresets()

    local record = PresetRegistry.Get(actualPreset._id)
    if record then
        self:SelectPreset(record)
    end
end

return State
