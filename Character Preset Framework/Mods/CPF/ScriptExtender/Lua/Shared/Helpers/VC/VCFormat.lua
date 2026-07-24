VCFormat = {}

function VCFormat:IsUUID(uuid)
    if type(uuid) ~= "string" then
        return false
    end

    return uuid:match("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$") ~= nil
end

return VCFormat
