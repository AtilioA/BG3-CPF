VCFormat = {}

VCFormat.NullUuid = "00000000-0000-0000-0000-000000000000"

---@return Guid
function VCFormat:CreateUUID()
    return string.gsub("xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx", "[xy]", function(c)
        return string.format("%x", c == "x" and Ext.Math.Random(0, 0xf) or Ext.Math.Random(8, 0xb))
    end)
end

function VCFormat:IsUUID(uuid)
    if type(uuid) ~= "string" then
        return false
    end

    return uuid:match("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$") ~= nil
end

return VCFormat
