-- Thanks FocusBG3 for sharing the code for updating portraits in SE v31!

---@class IconManager
--- Handles rendering and updating character portrait icons after preset application.
IconManager = {
    System = "ClientCharacterIconRender",
    VisualSetParams = {},
    MaterialsParams = {},
    MaterialPresetParams = {},
    StatsOverrides = {}
}

--- Delay (ms) before submitting an icon render request after preset apply.
--- Allows time for replication to propagate visual changes to the client entity.
local PORTRAIT_RENDER_DELAY_MS = 1000

---@param rgb vec3|vec4
---@return vec3
function IconManager:sRGBToLinearRGB(rgb)
    --[[
    -- Gamma correction to linear rgb
    for i = 1,3 do
        local c = rgb[i]
        if c <= 0.04045 then
            c = c / 12.92
        else
            c = ((c + 0.055) / 1.055) ^ 2.4
        end
        rgb[i] = c
    end
    --]]
    -- Game uses approximation
    return { rgb[1] ^ 2.2, rgb[2] ^ 2.2, rgb[3] ^ 2.2 }
end

function IconManager:RevertColorEdits()
    for templateId, parameters in pairs(self.VisualSetParams) do
        local template = Ext.Template.GetTemplate(templateId)
        if template ~= nil then
            Ext.Types.Unserialize(template.Equipment.VisualSet.MaterialOverrides.Vector3Parameters, parameters)
        end
        self.VisualSetParams[templateId] = nil
    end

    for materialId, parameters in pairs(self.MaterialsParams) do
        local material = Ext.Resource.Get(materialId, "Material")
        if material ~= nil then
            Ext.Types.Unserialize(material.Instance.Parameters.Vector3Parameters, parameters)
        end
        self.MaterialsParams[materialId] = nil
    end

    for presetId, parameters in pairs(self.MaterialPresetParams) do
        local preset = Ext.Resource.Get(presetId, "MaterialPreset")
        if preset ~= nil then
            Ext.Types.Unserialize(preset.Presets.Vector3Parameters, parameters)
        end
        self.MaterialPresetParams[presetId] = nil
    end

    for stat, originalTemplate in pairs(self.StatsOverrides) do
        Ext.Stats.Get(stat).RootTemplate = originalTemplate
    end
end

-- Does not overwrite parameter values that may already exist in overrides
---@param presetParameters {Color:boolean, Custom:boolean, Enabled:boolean, Parameter:FixedString, Value:any}[]
---@param overrides table
function IconManager:AddPresetParametersToOverrides(presetParameters, overrides)
    for _, presetOverride in ipairs(presetParameters) do
        local foundParam = false
        for _, override in ipairs(overrides) do
            if override.Parameter == presetOverride.Parameter then
                foundParam = true
                break
            end
        end

        if not foundParam then
            overrides[#overrides + 1] = {
                Override = presetOverride.Enabled,
                Parameter = presetOverride.Parameter,
                Preset = true,
                Value = presetOverride.Value,
                field_9 = 0
            }
        end
    end
end

---@param presetParameters {Color:boolean, Custom:boolean, Enabled:boolean, Parameter:FixedString, Value:any}[]
---@param overrides table
function IconManager:AddCCParametersToOverrides(presetParameters, overrides)
    for _, override in ipairs(presetParameters) do
        overrides[#overrides + 1] = {
            Override = override.Enabled,
            Parameter = override.Parameter,
            Preset = true,
            Value = override.Value,
            field_9 = 0
        }
    end
end

---@param item EntityHandle
---@return boolean
function IconManager:ShouldIncludeItemInPortrait(character, item)
    local slot = item.Equipable and item.Equipable.Slot
    if slot then
        local equipmentVisuals = character.ClientEquipmentVisuals.Equipment
        local isLoaded = equipmentVisuals[slot] ~= nil and equipmentVisuals[slot].Loaded
        if isLoaded then
            -- Underwear is always loaded if equipped, being hidden by vertex painting.
            -- TODO: Probably should look through character.Visual for underwear vertexmask.
            if slot == "Underwear" then
                local vanityBodyIsLoaded = equipmentVisuals.VanityBody ~= nil and equipmentVisuals.VanityBody.Loaded
                local chestIsLoaded = equipmentVisuals.Breast ~= nil and equipmentVisuals.Breast.Loaded
                return not vanityBodyIsLoaded and not chestIsLoaded
            else
                return isLoaded
            end
        end
    end

    return false
end

---@param character EntityHandle
---@param request EclCharacterIconRequestComponent
function IconManager:BuildRequestArmorSetState(character, request)
    local equipment = character.ClientEquipmentVisibilityState ~= nil and
        character.ClientEquipmentVisibilityState.Equipment
    if equipment then
        for slot in pairs(equipment) do
            if tostring(slot):find("^Vanity") then
                request.ArmorSetState = "Vanity"
                return
            end
        end
    end
    request.ArmorSetState = "Normal"
end

-- Adds character creation information to override tables within overrides
---@param character EntityHandle
---@param overrides MaterialParameterPresetsContainer
function IconManager:BuildRequestOverridesFromCharacterCreation(character, overrides)
    if character.CharacterCreationAppearance ~= nil then
        -- Add preset information
        local eyeColor = Ext.StaticData.Get(character.CharacterCreationAppearance.EyeColor, "CharacterCreationEyeColor")
        local eyeColorRes = eyeColor ~= nil and Ext.Resource.Get(eyeColor.MaterialPresetUUID, "MaterialPreset")
        local secondEyeColor = Ext.StaticData.Get(character.CharacterCreationAppearance.SecondEyeColor,
            "CharacterCreationEyeColor")
        local secondEyeColorRes = secondEyeColor ~= nil and
            Ext.Resource.Get(secondEyeColor.MaterialPresetUUID, "MaterialPreset")
        local hairColor = Ext.StaticData.Get(character.CharacterCreationAppearance.HairColor,
            "CharacterCreationHairColor")
        local hairColorRes = hairColor ~= nil and Ext.Resource.Get(hairColor.MaterialPresetUUID, "MaterialPreset")
        local skinColor = Ext.StaticData.Get(character.CharacterCreationAppearance.SkinColor,
            "CharacterCreationSkinColor")
        local skinColorRes = skinColor ~= nil and Ext.Resource.Get(skinColor.MaterialPresetUUID, "MaterialPreset")

        for _, res in pairs({ eyeColorRes, secondEyeColorRes, hairColorRes, skinColorRes }) do
            if res then
                self:AddPresetParametersToOverrides(res.Presets.ScalarParameters, overrides.FloatOverrides)
                self:AddPresetParametersToOverrides(res.Presets.Texture2DParameters, overrides.TextureOverrides)
                self:AddPresetParametersToOverrides(res.Presets.Vector2Parameters, overrides.Vec2Overrides)
                self:AddPresetParametersToOverrides(res.Presets.Vector3Parameters, overrides.Vec3Overrides)
                self:AddPresetParametersToOverrides(res.Presets.VectorParameters, overrides.Vec4Overrides)
                self:AddPresetParametersToOverrides(res.Presets.VirtualTextureParameters,
                    overrides.VirtualTextureOverrides)
            end
        end

        -- Add selectable CC option information
        for _, element in pairs(character.CharacterCreationAppearance.Elements) do
            local ccMaterial = Ext.StaticData.Get(element.Material, "CharacterCreationAppearanceMaterial")
            _D(ccMaterial)
            local materialPreset = ccMaterial ~= nil and
                Ext.Resource.Get(ccMaterial.MaterialPresetUUID, "MaterialPreset")
            if materialPreset then
                local materialPresets = materialPreset.Presets
                local colorDefinition = Ext.StaticData.Get(element.Color, "ColorDefinition")
                local rgb = colorDefinition ~= nil and self:sRGBToLinearRGB(colorDefinition.Color) or { 0, 0, 0 }

                if ccMaterial.MaterialTypeName == "Tattoo" then
                    local newParam = {
                        Override = true,
                        Parameter = "TattooColorB",
                        Preset = true,
                        field_9 = 0,
                        Value = rgb
                    }
                    overrides.Vec3Overrides[#overrides.Vec3Overrides + 1] = newParam
                end

                for _, param in ipairs(materialPresets.ScalarParameters) do
                    local newParam = {
                        Override = true,
                        Parameter = param.Parameter,
                        Preset = true,
                        field_9 = 0
                    }
                    --TODO: Roughness
                    if param.Parameter:find("Intensity$") then
                        newParam.Value = element.ColorIntensity
                    elseif param.Parameter:find("Color") then
                        newParam.Value = element.ColorIntensity -- TODO: Verify
                    elseif param.Parameter:find("Metalness$") then
                        newParam.Value = element.MetallicTint
                    else
                        newParam.Value = param.Value
                    end
                    overrides.FloatOverrides[#overrides.FloatOverrides + 1] = newParam
                end

                for _, param in pairs(materialPresets.Texture2DParameters) do
                    local newParam = {
                        Override = true,
                        Parameter = param.Parameter,
                        Preset = true,
                        field_9 = 0
                    }
                    newParam.Value = param.Value
                    overrides.TextureOverrides[#overrides.TextureOverrides + 1] = newParam
                end

                for _, param in pairs(materialPresets.Vector2Parameters) do
                    local newParam = {
                        Override = true,
                        Parameter = param.Parameter,
                        Preset = true,
                        field_9 = 0
                    }
                    newParam.Value = param.Value
                    overrides.Vec2Overrides[#overrides.Vec2Overrides + 1] = newParam
                end

                for _, param in pairs(materialPresets.Vector3Parameters) do
                    local newParam = {
                        Override = true,
                        Parameter = param.Parameter,
                        Preset = true,
                        field_9 = 0
                    }
                    if param.Parameter:find("Intensity$") then
                        newParam.Value = { 0, 0, element.ColorIntensity }
                    elseif param.Parameter:find("Color") then
                        newParam.Value = rgb -- TODO: Verify
                    else
                        newParam.Value = param.Value
                    end
                    overrides.Vec3Overrides[#overrides.Vec3Overrides + 1] = newParam
                end

                for _, param in pairs(materialPresets.VectorParameters) do
                    local newParam = {
                        Override = true,
                        Parameter = param.Parameter,
                        Preset = true,
                        field_9 = 0
                    }
                    if param.Parameter:find("Intensity$") then
                        newParam.Value = { 0, 0, element.ColorIntensity, 0 }
                    elseif param.Parameter:find("Color") then
                        newParam.Value = { rgb[1], rgb[2], rgb[3], 1 } -- TODO: Verify
                    else
                        newParam.Value = param.Value
                    end
                    overrides.Vec4Overrides[#overrides.Vec4Overrides + 1] = newParam
                end

                for _, param in pairs(materialPresets.VirtualTextureParameters) do
                    local newParam = {
                        Override = true,
                        Parameter = param.Parameter,
                        Preset = true,
                        field_9 = 0
                    }
                    newParam.Value = param.Value
                    overrides.VirtualTextureOverrides[#overrides.VirtualTextureOverrides + 1] = newParam
                end
            end
        end
    end
end

-- Script overrides, e.g. selune shart, ersatz eye, illithid
---@param character EntityHandle
---@param overrides MaterialParameterPresetsContainer
function IconManager:AddRequestOverridesFromScriptMaterialOverrides(character, overrides)
    local scriptOverrides = character.MaterialParameterOverride
    if scriptOverrides ~= nil then
        -- TODO: Move this somewhere sensible
        local ParamTypeOverrideTypes = {
            Integer = "FloatOverrides",
            Float = "FloatOverrides",
            Float2 = "Vec2Overrides",
            Float3 = "Vec3Overrides",
            Float4 = "Vec4Overrides",
            FixedString = "TextureOverrides", --TODO: Verify
        }

        for _, guid in pairs(scriptOverrides.field_0) do
            local presetOverride = Ext.StaticData.Get(guid, "ScriptMaterialPresetOverride")
            for _, parameterGuid in pairs(presetOverride.ParameterUuids) do
                local scriptParameter = Ext.StaticData.Get(parameterGuid, "ScriptMaterialParameterOverride")
                local paramType = scriptParameter.ParameterType
                local overrideType = paramType ~= "" and ParamTypeOverrideTypes[paramType]
                if overrideType then
                    local overrideGroup = overrides[overrideType]
                    local foundParam = false
                    for _, override in ipairs(overrideGroup) do
                        if override.Parameter == scriptParameter.ParameterName then
                            override.Value = scriptParameter.ParameterValue
                            foundParam = true
                            break
                        end
                    end

                    if not foundParam then
                        overrideGroup[#overrideGroup + 1] = {
                            Override = true,
                            Parameter = scriptParameter.ParameterName,
                            Preset = true,
                            Value = scriptParameter.ParameterValue,
                            field_9 = 0
                        }
                    end
                end
            end
        end
    end
end

---@param character EntityHandle
---@param request EclCharacterIconRequestComponent
function IconManager:BuildRequestEquipment(character, request)
    local equipment = {}
    local equippedItems = character.InventoryOwner.Inventories[#character.InventoryOwner.Inventories]

    for _, itemEntry in pairs(equippedItems.InventoryContainer.Items) do
        local item = itemEntry.Item
        if self:ShouldIncludeItemInPortrait(character, item) then
            local template = item.OriginalTemplate ~= nil and item.OriginalTemplate.OriginalTemplate ~= "" and
                Ext.Template.GetTemplate(item.OriginalTemplate.OriginalTemplate)
            if template then
                -- Fix templates that don't recurse on their visuals via stats
                local statsEntry = Ext.Stats.Get(template.Stats)
                if statsEntry.RootTemplate ~= "" and statsEntry.RootTemplate ~= item.OriginalTemplate.OriginalTemplate then
                    self.StatsOverrides[template.Stats] = statsEntry.RootTemplate
                    statsEntry.RootTemplate = item.OriginalTemplate.OriginalTemplate
                end

                equipment[#equipment + 1] = template.Name
                equipment[#equipment + 1] = template.Stats

                -- Color support
                local equipmentVisual = character.ClientEquipmentVisuals.Equipment[item.Equipable.Slot]
                if equipmentVisual ~= nil and equipmentVisual.VisualData ~= nil then
                    -- Flatten visual params on top of dye params
                    local colorParameters = {}
                    if item.ItemDye ~= nil then
                        local dyeResource = Ext.Resource.Get(item.ItemDye.Color, "MaterialPreset")
                        if dyeResource ~= nil then
                            colorParameters = Ext.Types.Serialize(dyeResource.Presets.Vector3Parameters)
                        end
                    end

                    local visualParams = Ext.Types.Serialize(equipmentVisual.VisualData.Vector3Parameters)
                    for _, visualParam in ipairs(visualParams) do
                        local matchedParam = false
                        for j, colorParam in ipairs(colorParameters) do
                            if visualParam.Parameter == colorParam.Parameter then
                                colorParameters[j] = visualParam
                                matchedParam = true
                                break
                            end
                        end

                        if not matchedParam then
                            colorParameters[#colorParameters + 1] = visualParam
                        end
                    end


                    local hasVisualSet = template.Equipment ~= nil and template.Equipment.VisualSet ~= nil
                    if hasVisualSet and not IconManager.VisualSetParams[template.Id] then
                        local overrideParams = Ext.Types.Serialize(template.Equipment.VisualSet.MaterialOverrides
                            .Vector3Parameters)
                        IconManager.VisualSetParams[template.Id] = overrideParams

                        local newOverrideParams = {}
                        for _, setParam in ipairs(overrideParams) do
                            local matchedParam = false
                            for _, colorParam in ipairs(colorParameters) do
                                if setParam.Parameter == colorParam.Parameter then
                                    newOverrideParams[#newOverrideParams + 1] = {
                                        Value = colorParam.Value,
                                        Custom = colorParam.Custom,
                                        Enabled = setParam.Enabled,
                                        Color = colorParam.Color,
                                        Parameter = colorParam.Parameter
                                    }
                                    matchedParam = true
                                    break
                                end
                            end

                            if not matchedParam then
                                newOverrideParams[#newOverrideParams + 1] = setParam
                            end
                        end

                        Ext.Types.Unserialize(template.Equipment.VisualSet.MaterialOverrides.Vector3Parameters,
                            newOverrideParams)

                        for _, preset in pairs(template.Equipment.VisualSet.MaterialOverrides.MaterialPresets) do
                            if preset.MaterialPresetResource ~= "00000000-0000-0000-0000-000000000000" and
                                not IconManager.MaterialPresetParams[preset.MaterialPresetResource] then
                                local presetResource = Ext.Resource.Get(preset.MaterialPresetResource, "MaterialPreset")
                                local presetParams = Ext.Types.Serialize(presetResource.Presets.Vector3Parameters)
                                IconManager.MaterialPresetParams[preset.MaterialPresetResource] = presetParams

                                for _, presetParam in ipairs(presetResource.Presets.Vector3Parameters) do
                                    for _, colorParam in ipairs(colorParameters) do
                                        if presetParam.Parameter == colorParam.Parameter then
                                            presetParam.Value = colorParam.Value
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            else
                equipment[#equipment + 1] = item.Data.StatsId
            end
        end
    end

    request.Equipment = equipment
end

---@param character EntityHandle
---@param request EclCharacterIconRequestComponent
function IconManager:BuildRequestTemplate(character, request)
    request.Template = character.ClientCharacter.OriginalTemplate.Id
end

---@param character EntityHandle
---@param request EclCharacterIconRequestComponent
function IconManager:BuildRequestTrigger(character, request)
    request.Trigger = character.ClientCharacter.OriginalTemplate.GeneratePortrait
end

---@param character EntityHandle
---@param request EclCharacterIconRequestComponent
function IconManager:BuildRequestVisual(character, request)
    request.Visual = Ext.Resource.Get(character.ClientCharacter.OriginalTemplate.CharacterVisualResourceID,
        "CharacterVisual").BaseVisual
end

---@param character EntityHandle
---@param overrides MaterialParameterPresetsContainer
function IconManager:BuildRequestVisualSetOverrides(character, overrides)
    local characterVisualResource = Ext.Resource.Get(
        character.ClientCharacter.OriginalTemplate.CharacterVisualResourceID, "CharacterVisual") --[[@as ResourceCharacterVisualResource]]
    local visualSetInfo = characterVisualResource.VisualSet

    self:AddPresetParametersToOverrides(visualSetInfo.MaterialOverrides.ScalarParameters, overrides.FloatOverrides)
    self:AddPresetParametersToOverrides(visualSetInfo.MaterialOverrides.Texture2DParameters, overrides.TextureOverrides)
    self:AddPresetParametersToOverrides(visualSetInfo.MaterialOverrides.Vector2Parameters, overrides.Vec2Overrides)
    self:AddPresetParametersToOverrides(visualSetInfo.MaterialOverrides.Vector3Parameters, overrides.Vec3Overrides)
    self:AddPresetParametersToOverrides(visualSetInfo.MaterialOverrides.VectorParameters, overrides.Vec4Overrides)
    self:AddPresetParametersToOverrides(visualSetInfo.MaterialOverrides.VirtualTextureParameters,
        overrides.VirtualTextureOverrides)
end

---@param character EntityHandle
---@param request EclCharacterIconRequestComponent
function IconManager:BuildRequestVisualSet(character, request)
    local characterVisualResource = Ext.Resource.Get(
        character.ClientCharacter.OriginalTemplate.CharacterVisualResourceID, "CharacterVisual") --[[@as ResourceCharacterVisualResource]]
    local visualSetInfo = characterVisualResource.VisualSet
    local visualSet = {
        LocatorAttachments = {},
        MaterialOverrides = {},
        MaterialParameters = {
            FloatOverrides = {},
            TextureOverrides = {},
            Vec2Overrides = {},
            Vec3Overrides = {},
            Vec4Overrides = {},
            VirtualTextureOverrides = {},
            Presets = {},
            field_60 = ""
        },
        MaterialRemaps = {},
        Materials = {},
        VisualSlots = {},
    }

    self:BuildRequestOverridesFromCharacterCreation(character, visualSet.MaterialParameters)

    visualSet.BodySetVisual = visualSetInfo.BodySetVisual

    for i, attachment in ipairs(visualSetInfo.LocatorAttachments) do
        visualSet.LocatorAttachments[i] = {
            LocatorName = attachment.LocatorId,
            DisplayName = attachment.VisualResource
        }
    end

    for k, v in pairs(visualSetInfo.RealMaterialOverrides) do
        visualSet.MaterialOverrides[k] = v
    end

    for k, preset in pairs(visualSetInfo.MaterialOverrides.MaterialPresets) do
        visualSet.MaterialParameters.Presets[k] = {
            CCPreset = preset.MaterialPresetResource,
            GroupName = preset.GroupName,
            field_8 = 0
        }
    end

    self:BuildRequestVisualSetOverrides(character, visualSet.MaterialParameters)

    for k, v in pairs(visualSetInfo.MaterialRemaps) do
        visualSet.MaterialRemaps[k] = v
    end

    visualSet.ShowEquipmentVisuals = visualSetInfo.ShowEquipmentVisuals
    visualSet.VisualSet = ""

    -- Scrape slot information from cloth visual attachments
    for _, attachment in ipairs(character.ClientCharacter.ClothVisual.Attachments) do
        if attachment.Flags & Ext.Enums.VisualAttachmentFlags.VisualSet ~= 0 then
            local visResource = attachment.Visual.VisualResource
            if visResource.Slot ~= "NakedBody" then
                visualSet.VisualSlots[#visualSet.VisualSlots + 1] = {
                    Slot = visResource.Slot,
                    Visual = visResource.Guid,
                    field_8 = visResource.AttachBone
                }
            end
        end
    end

    self:AddRequestOverridesFromScriptMaterialOverrides(character, visualSet.MaterialParameters)

    request.VisualSet = visualSet
end

---@param character EntityHandle
---@return table|nil
function IconManager:BuildRequestForCharacter(character)
    local request = {} --[[@as EclCharacterIconRequestComponent]]
    self:BuildRequestArmorSetState(character, request)
    self:BuildRequestEquipment(character, request)
    self:BuildRequestTemplate(character, request)
    self:BuildRequestTrigger(character, request)
    self:BuildRequestVisual(character, request)
    self:BuildRequestVisualSet(character, request)
    request.field_1B0 = 1

    return request
end

---@param request table Should have EclCharacterIconRequestComponent properties
function IconManager:SubmitRequest(request)
    local sys = Ext.System[self.System]
    sys.SessionCount = sys.SessionCount + 1
    local reqEntity = Ext.Entity.Create()
    local comp = reqEntity:CreateComponent("ClientCharacterIconRequest")
    for k in pairs(request) do
        comp[k] = request[k]
    end
end

---@param entity EntityHandle
---@param icon ScratchBuffer webp binary
function IconManager:SetIcon(entity, icon)
    local customIconComp = entity.CustomIcon or entity:CreateComponent("CustomIcon")
    customIconComp.Icon = icon
    customIconComp.Source = 0
    entity:Replicate("CustomIcon")

    local iconComp = entity.Icon or entity:CreateComponent("Icon")
    iconComp.Icon = "CustomIconSet"
    entity:Replicate("Icon")
end

--- Request a portrait update for a character entity.
--- Builds an icon render request, submits it, and sends the result to the server.
---@param characterUuid string UUID of the character to update
function IconManager:RequestPortraitUpdate(characterUuid)
    local targetEntity = Ext.Entity.Get(characterUuid)
    if targetEntity == nil then
        CPFWarn(0, "IconManager: Could not find entity for portrait update: " .. tostring(characterUuid))
        return
    end

    CPFPrint(1, "IconManager: Requesting portrait update for " .. tostring(characterUuid))

    Ext.Timer.WaitFor(PORTRAIT_RENDER_DELAY_MS, function()
        local success, err = pcall(function()
            local request = self:BuildRequestForCharacter(targetEntity)
            if request == nil then
                CPFWarn(0, "IconManager: Failed to build icon request")
                return
            end

            self:SubmitRequest(request)

            Ext.Entity.OnCreateDeferredOnce("ClientCharacterIconResult", function(entity)
                Ext.System.ClientCharacterIconRender.SessionCount = math.max(
                    Ext.System.ClientCharacterIconRender.SessionCount - 1, 0)
                NetChannels.IconUpdate:SendToServer({
                    Icon = entity.ClientCharacterIconResult.Icon,
                    Target = characterUuid
                })
                CPFPrint(1, "IconManager: Portrait updated for " .. tostring(characterUuid))
            end)
        end)

        if not success then
            CPFWarn(0, "IconManager: Error during portrait update: " .. tostring(err))
        end
    end)
end

-- Auto-revert color edits after icon render completes
Ext.Entity.OnCreateDeferred("ClientCharacterIconResult", function()
    IconManager:RevertColorEdits()
end)

return IconManager
