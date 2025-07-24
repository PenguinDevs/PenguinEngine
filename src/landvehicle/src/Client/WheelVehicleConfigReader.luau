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

function WheelVehicleConfigReader:Read(vehicleObj: Model): WheelVehicleTypes.WheelVehicleConfig
	local config = {}

	config.suspensions = self:_readSuspensions(vehicleObj)

	return config
end

function WheelVehicleConfigReader:_readSuspensions(vehicleObj: Model): { WheelVehicleTypes.SuspensionConfig }
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

			suspensionConfig.topLinkCFrameRelative = links.TopLink.CFrame
			suspensionConfig.midLinkCFrameRelative = links.MidLink.CFrame
			suspensionConfig.bottomLinkCFrameRelative = links.BottomLink.CFrame
			suspensionConfig.pivotPoint = links.PivotLink.CFrame
			suspensionConfig.wheelCFrameRelative = links.WheelLink.CFrame

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

			table.insert(suspensions, suspensionConfig)
		end
	end

	return suspensions
end

return WheelVehicleConfigReader
