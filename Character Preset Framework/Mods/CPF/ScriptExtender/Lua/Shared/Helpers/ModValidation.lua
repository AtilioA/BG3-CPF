---@class ModValidation
ModValidation = {}

--- Checks if a mod is relevant for dependency checks.
--- A relevant mod is one that is loaded and non-vanilla.
---@param mod table The mod to check.
---@return boolean - True if the mod is relevant, false otherwise.
function ModValidation:IsModRelevant(mod)
    return mod and mod.Info and mod.Info.ModuleUUID
        and Ext.Mod.IsModLoaded(mod.Info.ModuleUUID)
        and mod.Info.Author ~= "" and mod.Info.Author ~= "LS"
end

return ModValidation
