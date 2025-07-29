--[=[
    Simulate wheel on a whel-based vehicle.

    @client
    @class WheelVehicleWheelClient
]=]

local require = require(script.Parent.loader).load(script)

local BaseObject = require("BaseObject")
local WheelVehicleAttributes = require("WheelVehicleAttributes")
local WheelVehicleConstants = require("WheelVehicleConstants")
local WheelVehicleTypes = require("WheelVehicleTypes")
local WheelVehicleUtils = require("WheelVehicleUtils")

local Wheel = setmetatable({}, BaseObject)
Wheel.ClassName = "Wheel"
Wheel.__index = Wheel

export type Wheel = typeof(setmetatable(
	{} :: {
		_wheelLink: Attachment,
		_config: WheelVehicleTypes.WheelConfig,
		_links: WheelVehicleUtils.Links,
		_sign: number,
		attachment: Attachment,
		diameter: number,
		force: VectorForce,
		rotation: number,
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

	if self._obj:GetAttribute(WheelVehicleAttributes.POSITION):sub(2, 2) == WheelVehicleConstants.POSITIONS.LEFT then
		self._sign = -1
	else
		self._sign = 1
	end

	self.attachment = attachment
	self.rotation = 0

	self:SetConstants()

	self.force = Instance.new("VectorForce")
	self.force.Name = "RelativeForce"
	self.force.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
	self.force.Force = Vector3.new(0, 0, 0)
	self.force.Attachment0 = forceAttachment
	self.force.Parent = forceAttachment
	self._maid.force = self.force

	local part = Instance.new("Part", self._obj)
	part.CanCollide = false
	local weld = Instance.new("Weld", part)
	weld.Part0 = part
	weld.Part1 = wheelObj

	return self
end

function Wheel.SetConstants(self: Wheel)
	self.diameter = self._obj.Size.Y
	self._wheelLink = self._links.wheelLink
end

function Wheel.UpdateStepped(self: Wheel, deltaTimeSim: number)
	debug.profilebegin("WheelVehicleWheelClient:UpdateStepped")

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

	self.rotation += -velocityRelative.Z * self.diameter * math.pi * deltaTimeSim
	if self.rotation > 360 then
		self.rotation -= 360
	elseif self.rotation < 0 then
		self.rotation += 360
	end

	self.attachment.Orientation = Vector3.new(self.rotation, 0, 0)

	self.force.Force = Vector3.new(-velocityRelative.X * 100, 0, 0)

	debug.profileend()
end

return Wheel
