---Dummy test logic for testing client-server communication
---Test function to simulate preset application request
local function testRequestApplyPreset()
    CPFDebug(0, "Starting dummy test for RequestApplyPreset...")

    -- Get current character UUID
    local characterUuid = nil
    local player = _C()
    if player then
        characterUuid = player.Uuid.EntityUuid
        CPFDebug(0, "Using host character UUID: " .. characterUuid)
    else
        CPFDebug(0, "No host character found")
    end

    -- Create dummy preset payload
    local dummyPreset = {
        _id = "5e9e40609e564e25836a82569a81036e48bf",
        Name = "Example Preset",
        Author = "Volitio",
        Version = "1.0",
        Data = {
            AdditionalChoices = {},
            Elements = {},
            EyeColor = "...",
            HairColor = "...",
            SecondEyeColor = "...",
            SkinColor = "...",
            Visuals = {}
        }
    }


    CPFDebug(0, "Created dummy preset payload:")
    CPFDump(dummyPreset)

    -- Test options
    local testOptions = {
        DryRun = true,
        OnSuccess = function(response)
            CPFPrint(0, "✅ RequestApplyPreset test succeeded!")
            CPFDebug(0, "Response received:")
            CPFDump(response)
        end,
        OnFailure = function(warnings, response)
            CPFWarn(0, "⚠️ RequestApplyPreset test had warnings:")
            CPFDump(warnings)
            CPFDebug(0, "Full response:")
            CPFDump(response)
        end
    }

    CPFDebug(0, "Sending test request to server...")
    local success = RequestApplyPreset(characterUuid, dummyPreset, testOptions)

    if success then
        CPFDebug(0, "Test request sent successfully")
    else
        CPFWarn(0, "Failed to send test request")
    end
end

---Initialize test functions
local function initTestLogic()
    CPFDebug(0, "Initializing client test logic...")

    CPFDebug(0, "Running client-side tests...")

    -- Wait a bit more, then test preset application
    Ext.Timer.WaitFor(2000, function()
        testRequestApplyPreset()
    end) -- 2 second delay
end

-- Start tests when the session loads
-- Ext.Events.SessionLoaded:Subscribe(function()
-- CPFDebug(0, "Session loaded, scheduling tests...")
-- initTestLogic()
-- end)
