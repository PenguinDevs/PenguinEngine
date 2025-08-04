--[=[
    Simulate wheel on a wheel-based vehicle.

    @client
    @class WheelVehiclePacejkaWheelClient
]=]

local require = require(script.Parent.loader).load(script)

local BaseObject = require("BaseObject")
local WheelVehicleTypes = require("WheelVehicleTypes")
local WheelVehicleUtils = require("WheelVehicleUtils")
local WheelVehicleWheelClient = require("WheelVehicleWheelClient")

local PacejkaWheel = setmetatable({}, BaseObject)
PacejkaWheel.ClassName = "PacejkaWheel"
PacejkaWheel.__index = PacejkaWheel

export type PacejkaWheel =
	typeof(setmetatable({} :: {}, {} :: typeof({ __index = PacejkaWheel })))
	& WheelVehicleWheelClient.Wheel

function PacejkaWheel.new(
	wheelObj: BasePart,
	wheelConfig: WheelVehicleTypes.WheelConfig,
	links: WheelVehicleUtils.Links,
	forceAttachment: Attachment
): PacejkaWheel
	local self = setmetatable(WheelVehicleWheelClient.new(wheelObj, wheelConfig, links, forceAttachment), PacejkaWheel)

	return self
end

function PacejkaWheel.UpdateStepped(self: PacejkaWheel, deltaTimeSim: number, groundForce: number)
	debug.profilebegin("WheelVehiclePacejkaWheelClient:UpdateStepped")

	local wheelOrientation = self._wheelLink.WorldOrientation
	local velocityGlobal = self._obj.Velocity

	-- NOTE: Remember for whatever strange reason, the negative Z axis is the forward direction in Roblox.
	-- Here: -Z -> backward, +X -> left
	local velocityRelative =
		CFrame.fromOrientation(math.rad(wheelOrientation.X), math.rad(wheelOrientation.Y), math.rad(wheelOrientation.Z))
			:VectorToObjectSpace(velocityGlobal) -- * CFrame.lookAt(Vector3.new(0, 0, 0), -velocityGlobal.Unit):Inverse()

	-- Do nothing if NaN velocity.
	if not (velocityRelative.Z == velocityRelative.Z) then
		return
	end

	self.rotation += -velocityRelative.Z * deltaTimeSim / (self.diameter * math.pi) * 360
	if (self.rotation :: number) > 360 then
		self.rotation -= 360
	elseif (self.rotation :: number) < 0 then
		self.rotation += 360
	end

	self.attachment.Orientation = Vector3.new(self.rotation, 0, 0)

	-- TODO: A more advanced traction model required.
	local maxTraction = self._config.baseAdhesionCoefficient * groundForce
	self.force.Force = Vector3.new(math.clamp(-velocityRelative.X * 100, -maxTraction, maxTraction), 0, 0)

	debug.profileend()
end

return PacejkaWheel
