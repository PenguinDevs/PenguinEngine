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

type SteeringSuspension = {
	_suspension: WheelVehicleSuspensionClient.Suspension,
	lateralOffset: number,
	longitudinalOffset: number,
}

export type SuspensionController = typeof(setmetatable(
	{} :: {
		_suspensions: { WheelVehicleSuspensionClient.Suspension },
		_steeringSuspensions: { SteeringSuspension },
		_vehicleObj: Model,
		_maxRearLateralOffset: number,
		_maxLongitudinalOffset: number,
		_minLongitudinalOffset: number,
		wheelBase: number,
		steeringInput: number,
		accelerationInput: number,
		brakeInput: number,
		turningRadius: number,
		maxSteeringAngle: number, -- radians
	},
	{} :: typeof({ __index = SuspensionController })
)) & BaseObject.BaseObject

function SuspensionController.new(vehicleObj: Model, suspensions: { WheelVehicleSuspensionClient.Suspension })
	assert(vehicleObj:IsA("Model"), "Expected vehicleObj to be a Model")
	assert(vehicleObj.PrimaryPart, "Expected vehicleObj to have a PrimaryPart")

	local self: SuspensionController = setmetatable(BaseObject.new(vehicleObj), SuspensionController)

	self.steeringInput = 0
	self.accelerationInput = 0
	self.brakeInput = 0

	self.maxSteeringAngle = 0

	self._steeringSuspensions = {}
	self._maxRearLateralOffset = 0
	self._maxLongitudinalOffset = 0
	self._suspensions = suspensions
	self._vehicleObj = vehicleObj

	self:StoreSteeringSuspensions()

	return self
end

function SuspensionController.StoreSteeringSuspensions(self: SuspensionController)
	table.clear(self._steeringSuspensions)

	self._minLongitudinalOffset = math.huge
	self._maxLongitudinalOffset = 0
	self._maxRearLateralOffset = 0

	for _, suspension in pairs(self._suspensions) do
		local contactLink = suspension._links.topLink.CFrame
			* suspension._links.midLink.CFrame
			* suspension._links.bottomLink.CFrame
			* suspension._links.contactLink.CFrame
		self._minLongitudinalOffset = math.min(self._minLongitudinalOffset, contactLink.Position.Z)
		self._maxLongitudinalOffset = math.max(self._maxLongitudinalOffset, contactLink.Position.Z)

		if suspension._config.steering then
			self.maxSteeringAngle = math.max(self.maxSteeringAngle, math.rad(suspension._config.steering.maxAngle))
		else
			self._maxRearLateralOffset = math.max(math.abs(contactLink.Position.X), self._maxRearLateralOffset)
		end
	end

	for _, suspension in pairs(self._suspensions) do
		if suspension._config.steering then
			local contactLink = suspension._links.topLink.CFrame
				* suspension._links.midLink.CFrame
				* suspension._links.bottomLink.CFrame
				* suspension._links.contactLink.CFrame
			table.insert(self._steeringSuspensions, {
				_suspension = suspension,
				lateralOffset = contactLink.Position.X,
				longitudinalOffset = contactLink.Position.Z - self._minLongitudinalOffset,
			})
		end
	end

	self.wheelBase = math.abs(self._minLongitudinalOffset) + math.abs(self._maxLongitudinalOffset)
	self.turningRadius = self.wheelBase / math.atan(self.maxSteeringAngle)

	return self._steeringSuspensions
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

	for _, steeringSuspension in pairs(self._steeringSuspensions) do
		steeringSuspension._suspension.steeringAngle = math.atan(
			self.wheelBase
				/ (
					self.turningRadius
					+ math.sign(self.steeringInput)
						* math.sign(steeringSuspension.lateralOffset)
						* (self._maxRearLateralOffset * 2)
				)
		) * self.steeringInput
	end

	return
end

return SuspensionController
