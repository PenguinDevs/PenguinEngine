--[=[
    Manages a collection of suspensions under a single vehicle, with sway bar influence between pairs of suspensions.

	@client
    @class WheelVehicleSuspensionControllerClient
]=]

local require = require(script.Parent.loader).load(script)

local RunService = game:GetService("RunService")

local BaseObject = require("BaseObject")
local WheelVehicleSuspensionClient = require("WheelVehicleSuspensionClient")

local SUSPENSION_UPDATE_RATE = 0.2 -- seconds

local SuspensionController = setmetatable({}, BaseObject)
SuspensionController.ClassName = "SuspensionController"
SuspensionController.__index = SuspensionController

export type SuspensionController =
	typeof(setmetatable(
		{} :: { _lastUpdateTime: number, _suspensions: { WheelVehicleSuspensionClient.Suspension } },
		{} :: typeof({ __index = SuspensionController })
	))
	& BaseObject.BaseObject

function SuspensionController.new(vehicleObj: Model, suspensions: { WheelVehicleSuspensionClient.Suspension })
	assert(vehicleObj:IsA("Model"), "Expected vehicleObj to be a Model")
	assert(vehicleObj.PrimaryPart, "Expected vehicleObj to have a PrimaryPart")

	local self: SuspensionController = setmetatable(BaseObject.new(vehicleObj), SuspensionController)

	self._lastUpdateTime = 0
	self._suspensions = suspensions

	return self
end

function SuspensionController.Start(self: SuspensionController)
	self._maid._updateHeartbeat = RunService.PostSimulation:Connect(function(deltaTimeSim)
		self:UpdateStepped(deltaTimeSim)
	end)
end

function SuspensionController.Stop(self: SuspensionController)
	self._maid._updateHeartbeat = nil
end

function SuspensionController.UpdateStepped(self: SuspensionController, deltaTimeSim: number)
	if tick() - self._lastUpdateTime < SUSPENSION_UPDATE_RATE then
		return false
	end
	self._lastUpdateTime = tick()

	for _, suspension in pairs(self._suspensions) do
		suspension:UpdateStepped(deltaTimeSim)
	end

	return
end

return SuspensionController
