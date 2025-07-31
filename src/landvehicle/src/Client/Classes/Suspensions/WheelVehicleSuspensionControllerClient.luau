--[=[
    Manages a collection of suspensions under a single vehicle, with sway bar influence between pairs of suspensions.

	Also a steering and acceleration controller.
	A separate steering and acceleration controller was not abstracted for the sake of performance.

	@client
    @class WheelVehicleSuspensionControllerClient
]=]

local require = require(script.Parent.loader).load(script)

local RunService = game:GetService("RunService")

local BaseObject = require("BaseObject")
local WheelVehicleSuspensionClient = require("WheelVehicleSuspensionClient")

local SuspensionController = setmetatable({}, BaseObject)
SuspensionController.ClassName = "SuspensionController"
SuspensionController.__index = SuspensionController

export type SuspensionController = typeof(setmetatable(
	{} :: {
		_suspensions: { WheelVehicleSuspensionClient.Suspension },
		_vehicleObj: Model,
		steeringAngleInput: number,
		accelerationInput: number,
		brakeInput: number,
	},
	{} :: typeof({ __index = SuspensionController })
)) & BaseObject.BaseObject

function SuspensionController.new(vehicleObj: Model, suspensions: { WheelVehicleSuspensionClient.Suspension })
	assert(vehicleObj:IsA("Model"), "Expected vehicleObj to be a Model")
	assert(vehicleObj.PrimaryPart, "Expected vehicleObj to have a PrimaryPart")

	local self: SuspensionController = setmetatable(BaseObject.new(vehicleObj), SuspensionController)

	self.steeringAngleInput = 0
	self.accelerationInput = 0
	self.brakeInput = 0

	self._suspensions = suspensions
	self._vehicleObj = vehicleObj

	return self
end

function SuspensionController.Start(self: SuspensionController)
	self._maid._updateHeartbeat = RunService.PreSimulation:Connect(function(deltaTimeSim)
		self:UpdateStepped(deltaTimeSim)
	end)
end

function SuspensionController.Stop(self: SuspensionController)
	self._maid._updateHeartbeat = nil
end

function SuspensionController.UpdateStepped(self: SuspensionController, deltaTimeSim: number)
	for _, suspension in pairs(self._suspensions) do
		suspension:UpdateStepped(deltaTimeSim)
	end

	print(self.steeringAngleInput, self.accelerationInput, self.brakeInput)

	return
end

return SuspensionController
