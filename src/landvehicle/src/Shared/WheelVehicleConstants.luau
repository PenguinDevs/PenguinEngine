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

local DEFAULT_SUSPENSION_CONFIG = { -- Example right side suspension config.
	topLinkCFrameRelative = CFrame.new(0, 0, 0),
	midLinkCFrameRelative = CFrame.new(0.3, -1, 0),
	bottomLinkCFrameRelative = CFrame.new(0.1, -1, 0),
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

local constantsConstructing = {
	DEFAULT_CONFIG = {
		engine = {} :: EngineConstants.EngineConfig,
		suspensions = {} :: { WheelVehicleTypes.SuspensionConfig },
	} :: WheelVehicleTypes.WheelVehicleConfig,
	DEFAULT_CUSTOMISATION = {
		suspensions = {
			Front = {
				camber = -1,
				caster = 6.92,
				kpi = 13.92,
				toeIn = 0.0041,
			} :: WheelVehicleTypes.SuspensionCustomisation,
			Rear = {
				camber = -1.42,
				caster = 0,
				kpi = 0,
				toeIn = 0.0053,
			} :: WheelVehicleTypes.SuspensionCustomisation,
		},
	} :: WheelVehicleTypes.WheelVehicleCustomisation,
	Positions = {
		FrontLeft = "FL",
		FrontRight = "FR",
		RearLeft = "RL",
		RearRight = "RR",
		Front = "F",
		Rear = "R",
		Left = "L",
		Right = "R",
	},
}

for i = 1, 4 do
	local suspensionConfig = Table.deepCopy(DEFAULT_SUSPENSION_CONFIG)

	if i == 1 or i == 2 then
		-- Front left & right
		suspensionConfig.topLinkCFrameRelative =
			CFrame.new(DEFAULT_SUSPENSION_OFFSET_X, 0, -DEFAULT_SUSPENSION_OFFSET_MINUS_Z)
		suspensionConfig.midLinkCFrameRelative = CFrame.new(0.3, -1, 0)
		suspensionConfig.bottomLinkCFrameRelative = CFrame.new(0.1, -1.5, 0)
	elseif i == 3 or i == 4 then
		-- Rear left & right
		suspensionConfig.topLinkCFrameRelative =
			CFrame.new(DEFAULT_SUSPENSION_OFFSET_X, 0, DEFAULT_SUSPENSION_OFFSET_PLUS_Z)
		suspensionConfig.midLinkCFrameRelative = CFrame.new(0.1, -1, 0)
		suspensionConfig.bottomLinkCFrameRelative = CFrame.new(0.1, -1.5, 0)
		if suspensionConfig.wheel then
			suspensionConfig.wheel.CFrameRelative *= CFrame.new(0.2, 0, 0)
		end
	end

	table.insert(constantsConstructing.DEFAULT_CONFIG.suspensions, suspensionConfig)
end

WheelVehicleUtils.flipLinksAndWheels(constantsConstructing.DEFAULT_CONFIG.suspensions[1])
WheelVehicleUtils.flipLinksAndWheels(constantsConstructing.DEFAULT_CONFIG.suspensions[3])

for _, suspension in ipairs(constantsConstructing.DEFAULT_CONFIG.suspensions) do
	WheelVehicleUtils.ensureLinksAndWheelsFaceChildren(suspension)
end

return Table.readonly(constantsConstructing)
