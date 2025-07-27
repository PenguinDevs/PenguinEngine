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

local Suspension = setmetatable({}, BaseObject)
Suspension.ClassName = "Suspension"
Suspension.__index = Suspension

export type Suspension = typeof(setmetatable(
	{} :: {
		_config: WheelVehicleTypes.SuspensionConfig,
		_links: WheelVehicleUtils.Links,
		_sign: number,
		_vehicleObj: Model,
		currentHeight: number,
		force: VectorForce,
		spring: Spring.Spring<number>,
		topLinkHeight: number,
		maxHeight: number,
	},
	{} :: typeof({ __index = Suspension })
)) & BaseObject.BaseObject

function Suspension.new(vehicleObj: Model, config: WheelVehicleTypes.SuspensionConfig)
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

	self.currentHeight = 0

	self:SetHeights()

	self.force = Instance.new("VectorForce")
	self.force.Name = "SuspensionForce"
	self.force.RelativeTo = Enum.ActuatorRelativeTo.World
	self.force.Force = Vector3.new(0, 0, 0)
	self.force.Attachment0 = self._links.contactLink
	self.force.Parent = self._links.contactLink
	self._maid.force = self.force

	self.spring = Spring.new(0)

	return self
end

function Suspension.SetHeights(self: Suspension)
	self.maxHeight = math.abs(self._links.midLink.Position.Z) * MAX_HEIGHT_PERCENTAGE
	self.topLinkHeight = self._links.topLink.Position.Y - self._links.contactLink.Position.Y
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
		Vector3.new(0, -self.topLinkHeight, 0),
		raycast
	)

	if raycastResult then
		local hitPosition = raycastResult.Position
		local displacement = (hitPosition - contactLinkPosition).Magnitude

		self.currentHeight = displacement

		self.force.Force = Vector3.new(0, self._config.spring.stiffness * displacement, 0)
		print(self.force.Force)
	end

	debug.profileend()
end

return Suspension
