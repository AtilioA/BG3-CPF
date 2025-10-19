Table = {}

--- Deep copies a table.
--- @param origTable any The table to copy.
--- @return any - The copied table.
function Table.deepcopy(origTable)
    local origTable_type = type(origTable)
    local copy

    if origTable_type ~= 'table' then
        CPFDebug(0, "Table.deepcopy: origTable is not a table")
        return origTable
    end

    copy = {}
    for k, v in pairs(origTable) do
        copy[Table.deepcopy(k)] = Table.deepcopy(v)
    end
    return copy
end

return Table
