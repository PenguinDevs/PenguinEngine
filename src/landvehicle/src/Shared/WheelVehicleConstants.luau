--!strict
--[=[
	Holds constants for the wheel-based vehicle class.
	@class WheelVehicleConstants
]=]

local require = require(script.Parent.loader).load(script)

local EngineConstants = require("EngineConstants")
local Table = require("Table")
local WheelVehicleTypes = require("WheelVehicleTypes")
local WheelVehicleUtils = require("WheelVehicleUtils")

local DEFAULT_SUSPENSION_CONFIG = {
	topLinkCFrameRelative = CFrame.new(0, 0, 0),
	midLinkCFrameRelative = CFrame.new(0.3, -1, -1),
	bottomLinkCFrameRelative = CFrame.new(0.1, -1, -0.2),
	spring = {
		stiffness = 10000,
		damping = 1000,
	},
	wheel = {
		CFrameRelative = CFrame.new(1, 0, 0),
		radius = 1.5,
		span = 1.0,
	} :: WheelVehicleTypes.WheelConfig,
} :: WheelVehicleTypes.SuspensionConfig

local DEFAULT_SUSPENSION_OFFSET_MINUS_Z = 5.1875 -- Suspension offset towards the front
local DEFAULT_SUSPENSION_OFFSET_PLUS_Z = 7.1875 -- Suspension offset towards the rear
local DEFAULT_SUSPENSION_OFFSET_X = 3 -- Suspension offset towards the sides from PrimaryPart, assuming symmetrical

local DEFAULT_SUSPENSION_FRONT_MID_HEIGHT = 1
local DEFAULT_SUSPENSION_FRONT_MID_OFFSET_X = 0.3
local DEFAULT_SUSPENSION_FRONT_MID_OFFSET_Z = 0.4

local DEFAULT_SUSPENSION_FRONT_BOT_HEIGHT = 1.5
local DEFAULT_SUSPENSION_FRONT_BOT_OFFSET_X = 0.1
local DEFAULT_SUSPENSION_FRONT_BOT_OFFSET_Z = 0.6

local DEFAULT_SUSPENSION_REAR_MID_HEIGHT = 1
local DEFAULT_SUSPENSION_REAR_MID_OFFSET_X = 0.3
local DEFAULT_SUSPENSION_REAR_MID_OFFSET_Z = 0.2

local DEFAULT_SUSPENSION_REAR_BOT_HEIGHT = 1.5
local DEFAULT_SUSPENSION_REAR_BOT_OFFSET_X = 0.1
local DEFAULT_SUSPENSION_REAR_BOT_OFFSET_Z = 0.2

local constantsConstructing = {
	DEFAULT_CONFIG = {
		engine = {} :: EngineConstants.EngineConfig,
		suspensions = {} :: { WheelVehicleTypes.SuspensionConfig },
	} :: WheelVehicleTypes.WheelVehicleConfig,
}

for i = 1, 4 do
	local suspensionConfig = Table.deepCopy(DEFAULT_SUSPENSION_CONFIG)

	if i == 1 then
		-- Front left
		suspensionConfig.topLinkCFrameRelative =
			CFrame.new(-DEFAULT_SUSPENSION_OFFSET_X, 0, -DEFAULT_SUSPENSION_OFFSET_MINUS_Z)
		suspensionConfig.midLinkCFrameRelative = CFrame.new(
			DEFAULT_SUSPENSION_FRONT_MID_OFFSET_X,
			-DEFAULT_SUSPENSION_FRONT_MID_HEIGHT,
			-DEFAULT_SUSPENSION_FRONT_MID_OFFSET_Z
		)
		suspensionConfig.bottomLinkCFrameRelative = CFrame.new(
			DEFAULT_SUSPENSION_FRONT_BOT_OFFSET_X,
			-DEFAULT_SUSPENSION_FRONT_BOT_HEIGHT,
			-DEFAULT_SUSPENSION_FRONT_BOT_OFFSET_Z
		)
	elseif i == 2 then
		-- Front right
		suspensionConfig.topLinkCFrameRelative =
			CFrame.new(DEFAULT_SUSPENSION_OFFSET_X, 0, -DEFAULT_SUSPENSION_OFFSET_MINUS_Z)
		suspensionConfig.midLinkCFrameRelative = CFrame.new(
			DEFAULT_SUSPENSION_FRONT_MID_OFFSET_X,
			-DEFAULT_SUSPENSION_FRONT_MID_HEIGHT,
			-DEFAULT_SUSPENSION_FRONT_MID_OFFSET_Z
		)
		suspensionConfig.bottomLinkCFrameRelative = CFrame.new(
			DEFAULT_SUSPENSION_FRONT_BOT_OFFSET_X,
			-DEFAULT_SUSPENSION_FRONT_BOT_HEIGHT,
			-DEFAULT_SUSPENSION_FRONT_BOT_OFFSET_Z
		)
	elseif i == 3 then
		-- Rear left
		suspensionConfig.topLinkCFrameRelative =
			CFrame.new(-DEFAULT_SUSPENSION_OFFSET_X, 0, DEFAULT_SUSPENSION_OFFSET_PLUS_Z)
		suspensionConfig.midLinkCFrameRelative = CFrame.new(
			DEFAULT_SUSPENSION_REAR_MID_OFFSET_X,
			-DEFAULT_SUSPENSION_REAR_MID_HEIGHT,
			DEFAULT_SUSPENSION_REAR_MID_OFFSET_Z
		)
		suspensionConfig.bottomLinkCFrameRelative = CFrame.new(
			DEFAULT_SUSPENSION_REAR_BOT_OFFSET_X,
			-DEFAULT_SUSPENSION_REAR_BOT_HEIGHT,
			DEFAULT_SUSPENSION_REAR_BOT_OFFSET_Z
		)
	elseif i == 4 then
		-- Rear right
		suspensionConfig.topLinkCFrameRelative =
			CFrame.new(DEFAULT_SUSPENSION_OFFSET_X, 0, DEFAULT_SUSPENSION_OFFSET_PLUS_Z)
		suspensionConfig.midLinkCFrameRelative = CFrame.new(
			DEFAULT_SUSPENSION_REAR_MID_OFFSET_X,
			-DEFAULT_SUSPENSION_REAR_MID_HEIGHT,
			DEFAULT_SUSPENSION_REAR_MID_OFFSET_Z
		)
		suspensionConfig.bottomLinkCFrameRelative = CFrame.new(
			DEFAULT_SUSPENSION_REAR_BOT_OFFSET_X,
			-DEFAULT_SUSPENSION_REAR_BOT_HEIGHT,
			DEFAULT_SUSPENSION_REAR_BOT_OFFSET_Z
		)
	end

	table.insert(constantsConstructing.DEFAULT_CONFIG.suspensions, suspensionConfig)
end

for _, suspension in ipairs(constantsConstructing.DEFAULT_CONFIG.suspensions) do
	WheelVehicleUtils.ensureLinksAndWheelsFaceChildren(suspension)
end

return Table.readonly(constantsConstructing)
