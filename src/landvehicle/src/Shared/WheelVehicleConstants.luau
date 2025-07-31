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
		stiffness = 4500,
		damping = 300,
		extraLength = 0.5,
		radius = 0.2, -- Visually, the radius of the coil strip
	},
	suspension = {},
	steering = nil,
	wheelCFrameRelative = CFrame.new(0.66, 0, 0),
	wheel = {
		radius = 2.378 / 2,
		span = 0.81,
		baseAdhesionCoefficient = 0.8,
	} :: WheelVehicleTypes.WheelConfig,
} :: WheelVehicleTypes.SuspensionConfig

local DEFAULT_SUSPENSION_OFFSET_MINUS_Z = 9.46399974822998 / 2 -- Suspension offset towards the front
local DEFAULT_REAR_WHEEL_OFFSET_Z = -0.33
local DEFAULT_SUSPENSION_OFFSET_PLUS_Z = 9.46399974822998 / 2 - DEFAULT_REAR_WHEEL_OFFSET_Z -- Suspension offset towards the rear

local constantsConstructing = {
	DEFAULT_CONFIG = {
		chassis = {
			mass = 1240 / RMU_TO_KG, -- 1240 kg
			massSize = Vector3.new(9, 5, 16.5),
			massOffset = Vector3.new(0, 2, 0),
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
		STEERING_CONFIG = "SteeringConfig",
		WHEEL_HUBS = "WheelHubs",
		CONTROL_ARMS = "ControlArms",
		LOWER_STRUTS = "LowerStruts",
		UPPER_STRUTS = "UpperStruts",
		SEATS = "Seats",
	},
	SUSPENSION_TYPES = {
		MACPHERSON_STRUT = "MacPhersonStrut" :: WheelVehicleTypes.SuspensionTypes,
		MULTI_LINK = "MultiLink" :: WheelVehicleTypes.SuspensionTypes,
	},
	SEAT_TYPES = {
		DRIVER = "Driver" :: WheelVehicleTypes.SeatTypes,
		PASSENGER = "Passenger" :: WheelVehicleTypes.SeatTypes,
	},
}

for i = 1, 4 do
	local suspensionConfig = Table.deepCopy(DEFAULT_SUSPENSION_CONFIG)

	if i == 1 or i == 2 then
		-- Front left & right
		suspensionConfig.topLinkCFrameRelative = CFrame.new(2.26, 1.6, -DEFAULT_SUSPENSION_OFFSET_MINUS_Z)
		suspensionConfig.midLinkCFrameRelative = CFrame.new(0.07, -0.5, 0)
		suspensionConfig.bottomLinkCFrameRelative = CFrame.new(-0.04, -0.7, 0)
		suspensionConfig.wheelCFrameRelative += Vector3.new(-0.03, -0.4, 0)
		suspensionConfig.pivotPoint = suspensionConfig.topLinkCFrameRelative
			* suspensionConfig.midLinkCFrameRelative
			* suspensionConfig.bottomLinkCFrameRelative
			* suspensionConfig.wheelCFrameRelative
			* CFrame.new(-1.614, 0, 0)
		suspensionConfig.spring.radius = 0.3
		suspensionConfig.suspension = {
			type = "MacPhersonStrut",
			camberGain = 3,
		}
		suspensionConfig.steering = {
			enabled = true,
			maxAngle = 45, -- Maximum angle of the steering in degrees
		}
	elseif i == 3 or i == 4 then
		-- Rear left & right
		suspensionConfig.topLinkCFrameRelative = CFrame.new(2.23, 1.95, DEFAULT_SUSPENSION_OFFSET_PLUS_Z)
		suspensionConfig.midLinkCFrameRelative = CFrame.new(0, -0.83, 0)
		suspensionConfig.bottomLinkCFrameRelative = CFrame.new(0.079, -1.42, 0)
		suspensionConfig.wheelCFrameRelative += Vector3.new(0.01, 0.3, DEFAULT_REAR_WHEEL_OFFSET_Z)
		suspensionConfig.pivotPoint = suspensionConfig.topLinkCFrameRelative
			* suspensionConfig.midLinkCFrameRelative
			* suspensionConfig.bottomLinkCFrameRelative
			* suspensionConfig.wheelCFrameRelative
			* CFrame.new(-1.043, 0, 0)
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
