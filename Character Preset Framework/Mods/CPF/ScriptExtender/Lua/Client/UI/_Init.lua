local State = Ext.Require("Client/UI/State.lua")
local Window = Ext.Require("Client/UI/Window.lua")

-- Run preset discovery on client initialization
local presetCount = PresetDiscovery:LoadPresets()
CPFPrint(0, string.format("Discovered %d preset(s)", presetCount))

-- Populate UI state with discovered presets
State:RefreshPresets()

-- Create CPF window and render presets
Window:RenderCPFWindow()
