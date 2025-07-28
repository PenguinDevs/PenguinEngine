--[=[
    Suspension abstract base class.

	@client
    @class WheelVehicleSuspension
]=]

local require = require(script.Parent.loader).load(script)

local BaseObject = require("BaseObject")
local Spring = require("Spring")
local WheelVehicleConstants = require("WheelVehicleConstants")
local WheelVehicleTypes = require("WheelVehicleTypes")
local WheelVehicleUtils = require("WheelVehicleUtils")

local MAX_HEIGHT_PERCENTAGE = 0.8
local FORCE_TO_MASS_CAP = math.huge -- 2 * workspace.Gravity -- Force to mass ratio cap, used to prevent unrealistic forces

local Suspension = setmetatable({}, BaseObject)
Suspension.ClassName = "Suspension"
Suspension.__index = Suspension

export type Suspension = typeof(setmetatable(
	{} :: {
		_config: WheelVehicleTypes.SuspensionConfig,
		_links: WheelVehicleUtils.Links,
		_sign: number,
		_vehicleObj: Model,
		_topLinkHeight: number,
		_displacementToHeight: number,
		_lastHeight: number,
		_maxForce: number,
		currentHeight: number,
		forceAttachment: Attachment,
		force: VectorForce,
		spring: Spring.Spring<number>,
		maxHeight: number,
	},
	{} :: typeof({ __index = Suspension })
)) & BaseObject.BaseObject

function Suspension.new(vehicleObj: Model, config: WheelVehicleTypes.SuspensionConfig): Suspension
	assert(vehicleObj:IsA("Model"), "Expected vehicleObj to be a Model")
	assert(vehicleObj.PrimaryPart, "Expected vehicleObj to have a PrimaryPart")
	local links = WheelVehicleUtils:GetLinks(vehicleObj, config.position)

	local self: Suspension = setmetatable(BaseObject.new(links.topLink), Suspension)

	self._config = config
	self._links = links
	self._vehicleObj = vehicleObj

	if config.position:sub(2, 2) == WheelVehicleConstants.POSITIONS.LEFT then
		self._sign = 1
	else
		self._sign = -1
	end

	self._lastHeight = 0
	self._topLinkHeight = 0
	self._maxForce = 0

	self.maxHeight = 0
	self.currentHeight = 0

	self:SetConstants()

	local contactLinkOffset = self._links.topLink.CFrame
		* self._links.midLink.CFrame
		* self._links.bottomLink.CFrame
		* self._links.wheelLink.Position

	self.forceAttachment = Instance.new("Attachment")
	self.forceAttachment.Name = "SuspensionForceAttachment"
	self.forceAttachment.Position = Vector3.new(contactLinkOffset.X, 1, contactLinkOffset.Z)
	self.forceAttachment.Parent = self._vehicleObj.PrimaryPart

	self.force = Instance.new("VectorForce")
	self.force.Name = "SuspensionForce"
	self.force.RelativeTo = Enum.ActuatorRelativeTo.World
	self.force.Force = Vector3.new(0, 0, 0)
	self.force.Attachment0 = self.forceAttachment
	self.force.Parent = self.forceAttachment
	self._maid.force = self.force

	self.spring = Spring.new(0)

	return self
end

function Suspension.SetConstants(self: Suspension)
	assert(self._vehicleObj:IsA("Model"), "Expected vehicleObj to be a Model")
	assert(self._vehicleObj.PrimaryPart, "Expected vehicleObj to have a PrimaryPart")

	self.maxHeight = math.abs(self._links.midLink.Position.Z) * MAX_HEIGHT_PERCENTAGE
	self._topLinkHeight = self._links.topLink.Position.Y - self._links.contactLink.Position.Y
	local midLinkPositionOffsetFromTopLink = self._links.topLink.CFrame * self._links.midLink.Position
		- self._links.topLink.Position
	self._displacementToHeight =
		math.abs(midLinkPositionOffsetFromTopLink.Unit.Y / self._topLinkHeight * self._links.midLink.Position.Z)
	self._maxForce = FORCE_TO_MASS_CAP * self._vehicleObj.PrimaryPart.Mass / 4
end

function Suspension.UpdateStepped(self: Suspension, deltaTimeSim: number)
	debug.profilebegin("WheelVehicleSuspension:UpdateStepped")

	local contactLinkPosition = self._links.contactLink.WorldPosition
	local topLinkPosition = self._links.topLink.WorldPosition

	local raycast = RaycastParams.new()
	raycast.FilterType = Enum.RaycastFilterType.Exclude
	raycast.FilterDescendantsInstances = { self._vehicleObj }

	local raycastResult = workspace:Raycast(
		-- Can be simplified to contactLinkPosition for performance sake but inaccurate collisions
		Vector3.new(contactLinkPosition.X, topLinkPosition.Y, contactLinkPosition.Z),
		self.forceAttachment.WorldCFrame.UpVector * -self._topLinkHeight,
		raycast
	)

	if raycastResult then
		local hitPosition = raycastResult.Position
		local displacement = self._topLinkHeight - (hitPosition - topLinkPosition).Magnitude

		self.currentHeight = math.clamp(displacement * self._displacementToHeight, -self.maxHeight, self.maxHeight)

		local deltaVelocity = (self.currentHeight - self._lastHeight) / deltaTimeSim

		local force = math.clamp(
			displacement * self._config.spring.stiffness + deltaVelocity * self._config.spring.damping, -- (Spring stiffness + damper) RMU
			0,
			self._maxForce
		)

		self.force.Force = Vector3.new(0, force, 0)
	else
		self.force.Force = Vector3.new(0, 0, 0)
	end

	self._lastHeight = self.currentHeight

	debug.profileend()
end

-- Suspension.__newindex = function(self, key, value)
-- 	if key == "currentHeight" then
-- 		rawset(self, key, math.clamp(value, -self.maxHeight or 0, self.maxHeight or 0))
-- 	else
-- 		rawset(self, key, value)
-- 	end
-- end

return Suspension
