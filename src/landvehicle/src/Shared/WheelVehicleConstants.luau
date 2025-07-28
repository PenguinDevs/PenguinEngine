--!strict
--[=[
	Holds constants for the wheel-based vehicle class.
	@class WheelVehicleConstants
]=]

local require = require(script.Parent.loader).load(script)

-- local EngineConstants = require("EngineConstants")
local Table = require("Table")
local WheelVehicleTypes = require("WheelVehicleTypes")
local WheelVehicleUtils = require("WheelVehicleUtils")

-- Constants used for this constants file but not for public.
local RMU_TO_KG = 21.952

local DEFAULT_SUSPENSION_CONFIG = { -- Example right side suspension config.
	topLinkCFrameRelative = CFrame.new(),
	midLinkCFrameRelative = CFrame.new(0.3, -1, 0),
	bottomLinkCFrameRelative = CFrame.new(0.1, -1, 0),
	pivotPoint = CFrame.new(),
	spring = {
		stiffness = 6000,
		damping = 800,
		radius = 0.2,
	},
	suspension = {},
	wheelCFrameRelative = CFrame.new(0.66, 0, 0),
	wheel = {
		radius = 1.55,
		span = 1.025,
	} :: WheelVehicleTypes.WheelConfig,
} :: WheelVehicleTypes.SuspensionConfig

local DEFAULT_SUSPENSION_OFFSET_MINUS_Z = 5.988 -- Suspension offset towards the front
local DEFAULT_REAR_WHEEL_OFFSET_Z = -0.42
local DEFAULT_SUSPENSION_OFFSET_PLUS_Z = 5.988 - DEFAULT_REAR_WHEEL_OFFSET_Z -- Suspension offset towards the rear

local constantsConstructing = {
	DEFAULT_CONFIG = {
		chassis = {
			mass = 1240 / RMU_TO_KG, -- 1240 kg
			massSize = Vector3.new(11, 6.3, 21),
		} :: WheelVehicleTypes.ChassisConfig,
		-- engine = {} :: EngineConstants.EngineConfig,
		suspensions = {} :: { WheelVehicleTypes.SuspensionConfig },
	} :: WheelVehicleTypes.WheelVehicleConfig,
	DEFAULT_CUSTOMISATION = {
		suspensions = {
			Front = {
				camber = -1,
				caster = 6.92,
				kpi = 13.92,
				toeIn = 0.010361109839545355,
			} :: WheelVehicleTypes.SuspensionCustomisation,
			Rear = {
				camber = -1.42,
				caster = 0,
				kpi = 0,
				toeIn = 0.013469442791408964,
			} :: WheelVehicleTypes.SuspensionCustomisation,
		},
	} :: WheelVehicleTypes.WheelVehicleCustomisation,
	POSITIONS = {
		FRONT_LEFT = "FL" :: WheelVehicleTypes.Positions,
		FRONT_RIGHT = "FR" :: WheelVehicleTypes.Positions,
		REAR_LEFT = "RL" :: WheelVehicleTypes.Positions,
		REAR_RIGHT = "RR" :: WheelVehicleTypes.Positions,
		FRONT = "F",
		REAR = "R",
		LEFT = "L",
		RIGHT = "R",
	},
	FOLDERS = {
		SPRINGS = "Springs",
		WHEELS = "Wheels",
		SUSPENSION_CONFIG = "SuspensionConfig",
	},
	SUSPENSION_TYPES = {
		MACPHERSON_STRUT = "MacPhersonStrut" :: WheelVehicleTypes.SuspensionTypes,
		MULTI_LINK = "MultiLink" :: WheelVehicleTypes.SuspensionTypes,
	},
}

for i = 1, 4 do
	local suspensionConfig = Table.deepCopy(DEFAULT_SUSPENSION_CONFIG)

	if i == 1 or i == 2 then
		-- Front left & right
		suspensionConfig.topLinkCFrameRelative = CFrame.new(2.89, 2.08, -DEFAULT_SUSPENSION_OFFSET_MINUS_Z)
		suspensionConfig.midLinkCFrameRelative = CFrame.new(0.08, -0.63, 0)
		suspensionConfig.bottomLinkCFrameRelative = CFrame.new(-0.05, -0.98, 0)
		suspensionConfig.wheelCFrameRelative += Vector3.new(0.15, -0.5, 0)
		suspensionConfig.pivotPoint = suspensionConfig.topLinkCFrameRelative
			* suspensionConfig.midLinkCFrameRelative
			* suspensionConfig.bottomLinkCFrameRelative
			* suspensionConfig.wheelCFrameRelative
			* CFrame.new(-2, 0, 0)
		suspensionConfig.spring.radius = 0.4
		suspensionConfig.suspension = {
			type = "MacPhersonStrut",
			camberGain = 5,
		}
	elseif i == 3 or i == 4 then
		-- Rear left & right
		suspensionConfig.topLinkCFrameRelative = CFrame.new(2.82, 2.47, DEFAULT_SUSPENSION_OFFSET_PLUS_Z)
		suspensionConfig.midLinkCFrameRelative = CFrame.new(0, -1.05, 0)
		suspensionConfig.bottomLinkCFrameRelative = CFrame.new(0.1, -1.75, 0)
		suspensionConfig.wheelCFrameRelative += Vector3.new(0.2, 0.3, DEFAULT_REAR_WHEEL_OFFSET_Z)
		suspensionConfig.pivotPoint = suspensionConfig.topLinkCFrameRelative
			* suspensionConfig.midLinkCFrameRelative
			* suspensionConfig.bottomLinkCFrameRelative
			* suspensionConfig.wheelCFrameRelative
			* CFrame.new(-1.1, 0, 0)
		suspensionConfig.suspension = {
			type = "MultiLink",
			camberGain = 1,
		}
	end

	table.insert(constantsConstructing.DEFAULT_CONFIG.suspensions, suspensionConfig)
end

constantsConstructing.DEFAULT_CONFIG.suspensions[1].position = constantsConstructing.POSITIONS.FRONT_LEFT
constantsConstructing.DEFAULT_CONFIG.suspensions[2].position = constantsConstructing.POSITIONS.FRONT_RIGHT
constantsConstructing.DEFAULT_CONFIG.suspensions[3].position = constantsConstructing.POSITIONS.REAR_LEFT
constantsConstructing.DEFAULT_CONFIG.suspensions[4].position = constantsConstructing.POSITIONS.REAR_RIGHT

WheelVehicleUtils:FlipLinksAndWheels(constantsConstructing.DEFAULT_CONFIG.suspensions[1])
WheelVehicleUtils:FlipLinksAndWheels(constantsConstructing.DEFAULT_CONFIG.suspensions[3])

for _, suspension in ipairs(constantsConstructing.DEFAULT_CONFIG.suspensions) do
	WheelVehicleUtils:EnsureLinksAndWheelsFaceChildren(suspension)
end

return Table.readonly(constantsConstructing)
