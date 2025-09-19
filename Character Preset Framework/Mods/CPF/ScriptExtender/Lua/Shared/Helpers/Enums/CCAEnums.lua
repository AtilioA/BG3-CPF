--- @class CCAEnums
--- @field AdditionalChoices table<integer, string>
--- @field Elements table<integer, string>
CCAEnums = {}

--- AdditionalChoices enum mapping
--- Index mapping: 1 - Vitiligo, 2 - Freckles, 3 - FrecklesWeight, 4 - Oldness
CCAEnums.AdditionalChoices = {
    [1] = "Vitiligo",
    [2] = "Freckles",
    [3] = "FrecklesWeight",
    [4] = "Oldness",
}

--- Elements enum mapping
--- 1 - Face tats, 2 - Makeup, 3 - Scales, 4 - Hair graying, 5 - Hair highlights, 6 - Scar, 7 - Lips makeup, 8 - Horns color, 9 - Horns tip color
CCAEnums.Elements = {
    [1] = "FaceTats",
    [2] = "Makeup",
    [3] = "Scales",
    [4] = "HairGraying",
    [5] = "HairHighlights",
    [6] = "Scar",
    [7] = "LipsMakeup",
    [8] = "HornsColor",
    [9] = "HornsTipColor",
}

--- Get the human-readable name for an AdditionalChoices index
--- @param index integer|nil
--- @return string|nil
function CCAEnums.GetAdditionalChoiceName(index)
    if type(index) ~= "number" then
        return nil
    end
    return CCAEnums.AdditionalChoices[index]
end

--- Get the human-readable name for an Elements index
--- @param index integer|nil
--- @return string|nil
function CCAEnums.GetElementName(index)
    if type(index) ~= "number" then
        return nil
    end
    return CCAEnums.Elements[index]
end

--- Map a list of AdditionalChoices indices to structured entries with Name and Value
--- @param choices number[]|nil
--- @return table
function CCAEnums.MapAdditionalChoices(choices)
    local result = {}
    if choices == nil then
        return result
    end
    for i, value in ipairs(choices) do
        local name = CCAEnums.GetAdditionalChoiceName(i) -- Round to nearest integer for lookup
        table.insert(result, { Name = name, Value = value })
    end
    return result
end

--- Map a list of Elements indices to structured entries with Index and Name
--- @param elements integer[]|nil
--- @return table
function CCAEnums.MapElements(elements)
    local result = {}
    if elements == nil then
        return result
    end
    for _, n in ipairs(elements) do
        local name = CCAEnums.GetElementName(n)
        table.insert(result, { Index = n, Name = name })
    end
    return result
end

return CCAEnums
