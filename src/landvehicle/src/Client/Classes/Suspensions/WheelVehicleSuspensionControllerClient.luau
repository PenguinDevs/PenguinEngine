--[=[
    Manages a collection of suspensions under a single vehicle, with sway bar influence between pairs of suspensions.

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

export type SuspensionController =
	typeof(setmetatable(
		{} :: { _suspensions: { WheelVehicleSuspensionClient.Suspension }, _vehicleObj: Model },
		{} :: typeof({ __index = SuspensionController })
	))
	& BaseObject.BaseObject

function SuspensionController.new(vehicleObj: Model, suspensions: { WheelVehicleSuspensionClient.Suspension })
	assert(vehicleObj:IsA("Model"), "Expected vehicleObj to be a Model")
	assert(vehicleObj.PrimaryPart, "Expected vehicleObj to have a PrimaryPart")

	local self: SuspensionController = setmetatable(BaseObject.new(vehicleObj), SuspensionController)

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

	return
end

return SuspensionController
