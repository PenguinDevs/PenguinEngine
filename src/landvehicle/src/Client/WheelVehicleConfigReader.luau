--!strict

--[=[
    Obtain a configuration from a datamodel with the vehicle configuration already applied.
    @class WheelVehicleConfigReader
]=]

local require = require(script.Parent.loader).load(script)

local WheelVehicleAttributes = require("WheelVehicleAttributes")
local WheelVehicleConstants = require("WheelVehicleConstants")
local WheelVehicleTypes = require("WheelVehicleTypes")
local WheelVehicleUtils = require("WheelVehicleUtils")

local WheelVehicleConfigReader = {}

export type WheelVehicleConfigReader = typeof(setmetatable(
	{} :: {},
	{} :: typeof({ __index = WheelVehicleConfigReader })
))

function WheelVehicleConfigReader.Read(
	self: WheelVehicleConfigReader,
	vehicleObj: Model
): WheelVehicleTypes.WheelVehicleConfig
	assert(vehicleObj:IsA("Model"), "Expected vehicleObj to be a Model")
	assert(vehicleObj.PrimaryPart, "Expected vehicleObj to have a PrimaryPart")

	local config = {}

	config.suspensions = self:_readSuspensions(vehicleObj)
	config.chassis = {
		mass = vehicleObj:GetAttribute(WheelVehicleAttributes.MASS) :: number,
		massSize = vehicleObj:GetAttribute(WheelVehicleAttributes.MASS_SIZE) :: Vector3,
		massOffset = vehicleObj:GetAttribute(WheelVehicleAttributes.MASS_OFFSET) :: Vector3,
	}

	return config
end

function WheelVehicleConfigReader._readSuspensions(
	self: WheelVehicleConfigReader,
	vehicleObj: Model
): { WheelVehicleTypes.SuspensionConfig }
	assert(vehicleObj:IsA("Model"), "Expected vehicleObj to be a Model")
	assert(vehicleObj.PrimaryPart, "Expected vehicleObj to have a PrimaryPart")

	local springsFolder = vehicleObj:WaitForChild(WheelVehicleConstants.FOLDERS.SPRINGS)
	local wheelsFolder = vehicleObj:WaitForChild(WheelVehicleConstants.FOLDERS.WHEELS)

	local suspensions = {}

	for _, suspensionObj in springsFolder:GetChildren() do
		if suspensionObj:IsA("SpringConstraint") then
			local suspensionConfig = {} :: WheelVehicleTypes.SuspensionConfig

			local position = suspensionObj:GetAttribute(WheelVehicleAttributes.POSITION)
			local links = WheelVehicleUtils:GetLinks(vehicleObj, position :: WheelVehicleTypes.Positions)

			suspensionConfig.position =
				links.topLink:GetAttribute(WheelVehicleAttributes.POSITION) :: WheelVehicleTypes.Positions
			suspensionConfig.topLinkCFrameRelative = links.topLink.CFrame
			suspensionConfig.midLinkCFrameRelative = links.midLink.CFrame
			suspensionConfig.bottomLinkCFrameRelative = links.bottomLink.CFrame
			suspensionConfig.pivotPoint = links.pivotLink.CFrame
			suspensionConfig.wheelCFrameRelative = links.wheelLink.CFrame

			suspensionConfig.spring = {
				stiffness = suspensionObj:GetAttribute(WheelVehicleAttributes.SUSPENSION_STIFFNESS) :: number,
				damping = suspensionObj:GetAttribute(WheelVehicleAttributes.SUSPENSION_DAMPING) :: number,
				radius = suspensionObj.Radius,
			}

			local wheelObj = wheelsFolder:FindFirstChild(`Wheel{position}`) :: BasePart?
			if wheelObj then
				suspensionConfig.wheel = {
					radius = wheelObj.Size.Z,
					span = wheelObj.Size.X / 2,
				}
			end

			local suspensionFolder =
				links.topLink:FindFirstChild(WheelVehicleConstants.FOLDERS.SUSPENSION_CONFIG) :: Configuration
			assert(suspensionFolder, "Expected suspension config folder to exist")
			suspensionConfig.suspension = suspensionFolder:GetAttributes()

			table.insert(suspensions, suspensionConfig)
		end
	end

	return suspensions
end

return WheelVehicleConfigReader
