local State = Ext.Require("Client/UI/State.lua")
local MCMIntegration = Ext.Require("Client/UI/MCMIntegration.lua")
local MessageBox = Ext.Require("Client/UI/Components/MessageBox.lua")

RequireFiles("Client/UI/Styles/", {
    "_Init"
})

-- Run preset discovery on client initialization
local presetCount = PresetDiscovery:LoadPresets()
CPFPrint(0, string.format("Discovered %d preset(s)", presetCount))

-- Populate UI state with discovered presets
State:RefreshPresets()

MCMIntegration.Initialize()
