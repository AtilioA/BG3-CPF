Table = {}

--- Deep copies a table.
--- @param origTable any The table to copy.
--- @return any - The copied table.
function Table.deepcopy(origTable)
    local origTable_type = type(origTable)
    local copy

    if origTable_type ~= 'table' and origTable_type ~= 'userdata' then
        CPFDebug(3, "Table.deepcopy: origTable is not a table")
        return origTable
    end

    copy = {}
    for k, v in pairs(origTable) do
        copy[Table.deepcopy(k)] = Table.deepcopy(v)
    end
    return copy
end

--- Checks if a table is an array (has numeric indices)
--- @param tbl table The table to check
--- @return boolean isArray Whether the table is an array
function Table.IsArray(tbl)
    if type(tbl) ~= "table" then
        return false
    end

    for k, _ in pairs(tbl) do
        if type(k) == "number" then
            return true
        end
    end

    return false
end

return Table
