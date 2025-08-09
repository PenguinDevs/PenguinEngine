--[=[
    Simulate wheel on a wheel-based vehicle.

    @client
    @class WheelVehicleWheelClient
]=]

local require = require(script.Parent.loader).load(script)

local BaseObject = require("BaseObject")
local WheelVehicleAttributes = require("WheelVehicleAttributes")
local WheelVehicleConstants = require("WheelVehicleConstants")
local WheelVehicleTypes = require("WheelVehicleTypes")
local WheelVehicleUtils = require("WheelVehicleUtils")

local PI = math.pi
local TWO_PI = PI * 2

local Wheel = setmetatable({}, BaseObject)
Wheel.ClassName = "Wheel"
Wheel.__index = Wheel

export type Wheel = typeof(setmetatable(
	{} :: {
		_wheelLink: Attachment,
		_config: WheelVehicleTypes.WheelConfig,
		_links: WheelVehicleUtils.Links,
		_sign: number,
		_lastUpdated: number,
		_previousLongitudeVelocity: number,
		_forceAttachment: Attachment,
		attachment: Attachment,
		angularVelocity: number, -- radians per second
		baseTorque: number,
		radius: number,
		rotation: number, -- radians
		mass: number,
	},
	{} :: typeof({ __index = Wheel })
)) & BaseObject.BaseObject

function Wheel.new(
	wheelObj: BasePart,
	wheelConfig: WheelVehicleTypes.WheelConfig,
	links: WheelVehicleUtils.Links,
	forceAttachment: Attachment
): Wheel
	local attachment = wheelObj:FindFirstChild("RigidAttachment")
	assert(attachment, "Expected wheelObj to have a RigidAttachment")

	local self = setmetatable(BaseObject.new(wheelObj), Wheel)

	self._config = wheelConfig
	self._links = links
	self._forceAttachment = forceAttachment
	self._previousLongitudeVelocity = 0
	self.angularVelocity = 0
	self.baseTorque = 0

	if self._obj:GetAttribute(WheelVehicleAttributes.POSITION):sub(2, 2) == WheelVehicleConstants.POSITIONS.LEFT then
		self._sign = -1
	else
		self._sign = 1
	end

	self.attachment = attachment
	self.rotation = 0

	self:SetConstants()

	return self
end

function Wheel.SetConstants(self: Wheel)
	self.radius = self._obj.Size.Y / 2
	self._wheelLink = self._links.wheelLink
	self.mass = self._config.mass
end

function Wheel.UpdateStepped(
	self: Wheel,
	deltaTimeSim: number,
	verticalForce: number,
	contactNormal: Vector3
): (number, number)
	debug.profilebegin("WheelVehicleWheelClient:UpdateStepped")

	local wheelOrientation = self._wheelLink.WorldOrientation
	local velocityGlobal = self._obj.Velocity

	-- NOTE: Remember for whatever strange reason, the negative Z axis is the forward direction in Roblox.
	-- Here: -Z -> backward, +X -> left
	local velocityRelative =
		CFrame.fromOrientation(math.rad(wheelOrientation.X), math.rad(wheelOrientation.Y), math.rad(wheelOrientation.Z))
			:VectorToObjectSpace(velocityGlobal) -- * CFrame.lookAt(Vector3.new(0, 0, 0), -velocityGlobal.Unit):Inverse()

	-- Do nothing if NaN velocity.
	local longitudeVelocity = -velocityRelative.Z
	local deltaLongitudeVelocity = longitudeVelocity - self._previousLongitudeVelocity
	self._previousLongitudeVelocity = longitudeVelocity
	-- local lateralVelocity = velocityRelative.X
	if not (longitudeVelocity == longitudeVelocity) then
		return 0, 0
	end

	-- Wheel rotation
	local angularVelocityRelative = longitudeVelocity / self.radius - self.angularVelocity

	local torqueResistance = deltaLongitudeVelocity / deltaTimeSim * self.mass * self.radius

	local torque = self.baseTorque
	if longitudeVelocity ~= 0 and verticalForce > 0 then
		-- NOTE: A very basic unrealistic implementation to just get the wheel spinning.
		torque += angularVelocityRelative * 100 - torqueResistance
	end

	self.angularVelocity += torque * deltaTimeSim

	self.rotation += self.angularVelocity * deltaTimeSim
	if self.rotation > TWO_PI then
		self.rotation -= TWO_PI
	elseif self.rotation < 0 then
		self.rotation += TWO_PI
	end

	-- self.attachment.Orientation = Vector3.new(math.deg(self.rotation), 0, 0)
	self.attachment.CFrame = CFrame.Angles(self.rotation, 0, 0)

	-- TODO: A more advanced traction model required.
	local maxTraction = self._config.baseAdhesionCoefficient * verticalForce

	debug.profileend()

	return math.clamp(-velocityRelative.X * 100, -maxTraction, maxTraction),
		math.clamp(angularVelocityRelative * 100, -maxTraction, maxTraction)
end

function Wheel.ApplyModel(self: Wheel, model: Model): Model
	assert(model.PrimaryPart, "Wheel must have a PrimaryPart set before applying the model.")
	local attachment =
		assert(model.PrimaryPart:FindFirstChild("WeldAttachment"), "Expected PrimaryPart to have a WeldAttachment")

	local weld = Instance.new("Weld")
	weld.Part0 = self._obj
	weld.Part1 = model.PrimaryPart
	weld.C0 = attachment.CFrame
	weld.Parent = model

	attachment:Destroy()

	return model
end

return Wheel
