--[=[
    Suspension abstract base class.

	@client
    @class WheelVehicleSuspension
]=]

local require = require(script.Parent.loader).load(script)

local BaseObject = require("BaseObject")
local Spring = require("Spring")
local WheelVehicleAttributes = require("WheelVehicleAttributes")
local WheelVehicleConstants = require("WheelVehicleConstants")
local WheelVehicleTypes = require("WheelVehicleTypes")
local WheelVehicleUtils = require("WheelVehicleUtils")
local WheelVehicleWheelClient = require("WheelVehicleWheelClient")

local MAX_HEIGHT_PERCENTAGE = 0.8
local FORCE_TO_MASS_CAP = math.huge -- 2 * workspace.Gravity -- Force to mass ratio cap, used to prevent unrealistic forces
local STEPPED_INTERVAL = 1 / 60

local Suspension = setmetatable({}, BaseObject)
Suspension.ClassName = "Suspension"
Suspension.__index = Suspension

type movementType = "Motor6D"

export type Suspension = typeof(setmetatable(
	{} :: {
		_controlArmAngle: number,
		_config: WheelVehicleTypes.SuspensionConfig,
		_controlArms: { { model: Model, movementType: movementType, angleFactor: number } },
		_links: WheelVehicleUtils.Links,
		_initialBottomLinkCFrame: CFrame,
		_sign: number,
		_elapsedDeltaTimeSim: number,
		_vehicleObj: Model,
		_topLinkHeight: number,
		_lastHeight: number,
		_maxForce: number,
		currentHeight: number,
		forceAttachment: Attachment,
		force: VectorForce,
		raycastParams: RaycastParams,
		spring: Spring.Spring<number>,
		steeringAngle: number, -- radians
		steeringEnabled: boolean,
		maxHeight: number,
		wheel: WheelVehicleWheelClient.Wheel?,
	},
	{} :: typeof({ __index = Suspension })
)) & BaseObject.BaseObject

function Suspension.new(vehicleObj: Model, config: WheelVehicleTypes.SuspensionConfig): Suspension
	assert(vehicleObj:IsA("Model"), "Expected vehicleObj to be a Model")
	assert(vehicleObj.PrimaryPart, "Expected vehicleObj to have a PrimaryPart")
	local links = WheelVehicleUtils:GetLinks(vehicleObj, config.position)

	local self: Suspension = setmetatable(BaseObject.new(links.topLink), Suspension)

	self._controlArmAngle = 0
	self._config = config
	self._controlArms = {}
	self._links = links
	self._initialBottomLinkCFrame = self._links.bottomLink.CFrame
	self._vehicleObj = vehicleObj

	if self._config.position:sub(2, 2) == WheelVehicleConstants.POSITIONS.LEFT then
		self._sign = 1
	else
		self._sign = -1
	end

	self._elapsedDeltaTimeSim = 0
	self._lastHeight = 0
	self._topLinkHeight = 0
	self._maxForce = 0

	self.currentHeight = 0
	self.maxHeight = 0
	self.steeringAngle = 0

	self:SetConstants()

	local contactLinkOffset = self._links.topLink.CFrame
		* self._links.midLink.CFrame
		* self._links.bottomLink.CFrame
		* self._links.wheelLink.CFrame
		* self._links.contactLink.Position

	self.forceAttachment = Instance.new("Attachment")
	self.forceAttachment.Name = "ContactForceAttachment"
	self.forceAttachment.Position = contactLinkOffset
	self.forceAttachment.Parent = self._vehicleObj.PrimaryPart
	self._maid.forceAttachment = self.forceAttachment

	self.force = Instance.new("VectorForce")
	self.force.Name = "GlobalForce"
	self.force.RelativeTo = Enum.ActuatorRelativeTo.World
	self.force.Force = Vector3.new(0, 0, 0)
	self.force.Attachment0 = self.forceAttachment
	self.force.Parent = self.forceAttachment
	self._maid.force = self.force

	self.raycastParams = RaycastParams.new()
	self.raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	self.raycastParams.FilterDescendantsInstances = { self._vehicleObj }

	self.spring = Spring.new(0)
	self.spring.Speed = self._config.spring.stiffness / workspace.Gravity
	self.spring.Damper = self._config.spring.damping / workspace.Gravity / 5 -- 5 is a magic number

	if self._config.steering then
		self.steeringEnabled = true
	end

	return self
end

function Suspension.SetConstants(self: Suspension)
	assert(self._vehicleObj:IsA("Model"), "Expected vehicleObj to be a Model")
	assert(self._vehicleObj.PrimaryPart, "Expected vehicleObj to have a PrimaryPart")

	self.maxHeight = math.abs(self._links.midLink.Position.Z) * MAX_HEIGHT_PERCENTAGE
	self._topLinkHeight = self._links.topLink.Position.Y - self._links.contactLink.Position.Y
	self._maxForce = FORCE_TO_MASS_CAP * self._vehicleObj.PrimaryPart.Mass / 4
end

function Suspension.UpdateStepped(self: Suspension, subDeltaTimeSim: number)
	debug.profilebegin("WheelVehicleSuspension:UpdateStepped")

	self._elapsedDeltaTimeSim += subDeltaTimeSim
	if self._elapsedDeltaTimeSim <= STEPPED_INTERVAL then
		return
	end
	local deltaTimeSim = self._elapsedDeltaTimeSim
	self._elapsedDeltaTimeSim = 0

	self._controlArmAngle = math.asin(self.currentHeight / self._radius)

	local contactLinkPosition = self._links.contactLink.WorldPosition
	local topLinkPosition = self._links.topLink.WorldPosition

	local lookVector = CFrame.new(topLinkPosition, contactLinkPosition).LookVector
	local gravityFactor = lookVector.Y

	local rayLength = self._topLinkHeight + self._config.spring.extraLength

	-- Can be simplified to contactLinkPosition for performance sake but inaccurate collisions
	local rayOrigin = Vector3.new(contactLinkPosition.X, topLinkPosition.Y, contactLinkPosition.Z)
	local raycastResult =
		workspace:Raycast(rayOrigin, self.forceAttachment.WorldCFrame.UpVector * -rayLength, self.raycastParams)

	local force = 0

	if raycastResult and gravityFactor < -0.1 then
		-- Wheel contact.

		local displacement = rayLength - (rayOrigin - raycastResult.Position).Magnitude

		self.currentHeight = math.clamp(displacement - self._config.spring.extraLength, -self.maxHeight, self.maxHeight)

		local deltaVelocity = (self.currentHeight - self._lastHeight) / deltaTimeSim

		-- TODO: Maybe use gravityFactor to influence the force between wheels and contact?
		force = math.clamp(
			displacement * self._config.spring.stiffness + deltaVelocity * self._config.spring.damping, -- (Spring stiffness + damper) RMU
			0,
			self._maxForce
		)

		self._lastHeight = self.currentHeight
	else
		-- No wheel contact.

		local extendedRayOrigin =
			Vector3.new(contactLinkPosition.X, topLinkPosition.Y - self._topLinkHeight, contactLinkPosition.Z)
		local extendedRaycastResult = workspace:Raycast(
			extendedRayOrigin,
			self.forceAttachment.WorldCFrame.UpVector * -self.maxHeight,
			self.raycastParams
		)

		if extendedRaycastResult then
			local displacement = -(extendedRayOrigin - extendedRaycastResult.Position).Magnitude

			self.spring:SetTarget(displacement * -gravityFactor, true)
		else
			self.spring:SetTarget(-self.maxHeight * -gravityFactor, false)
		end

		self.currentHeight = self.spring.Position
	end

	self.force.Force = Vector3.new(0, force, 0)

	if self.wheel then
		self.wheel:UpdateStepped(deltaTimeSim, force)
	end

	-- if self._config.position == WheelVehicleConstants.POSITIONS.REAR_LEFT then
	-- 	print(-gravityFactor)
	-- end

	self:AnimateComponents()

	debug.profileend()
end

function Suspension.ApplyWheelHubModel(self: Suspension, model: Model)
	assert(model:IsA("Model"), "Expected model to be a Model")
	assert(model.PrimaryPart, "Expected model to have a PrimaryPart")
	local attachment = assert(
		model.PrimaryPart:FindFirstChild("WeldAttachment"),
		"Expected model to have a WeldAttachment in its PrimaryPart"
	)

	local rigidConstraint = Instance.new("RigidConstraint")
	rigidConstraint.Name = "WheelHubConstraint"
	rigidConstraint.Attachment0 = self._links.bottomLink
	rigidConstraint.Attachment1 = attachment
	rigidConstraint.Parent = model

	return self.wheel
end

function Suspension.ApplyControlArmModel(self: Suspension, model: Model)
	assert(model:IsA("Model"), "Expected model to be a Model")
	assert(model.PrimaryPart, "Expected model to have a PrimaryPart")

	local movementType
	local controlArm

	if model:FindFirstChild("ControlArmMotor6D") then
		movementType = "Motor6D"
		controlArm = {
			motor = model:FindFirstChild("ControlArmMotor6D") :: Motor6D,
		}
	end

	assert(movementType, "Expected model to have a valid MovementType")

	controlArm.model = model
	controlArm.movementType = movementType
	controlArm.angleFactor = if controlArm.motor:GetAttribute(WheelVehicleAttributes.MOTOR_ANGLE_FACTOR)
		then controlArm.motor:GetAttribute(WheelVehicleAttributes.MOTOR_ANGLE_FACTOR) :: number
		else 1
	table.insert(self._controlArms, controlArm)

	return controlArm
end

function Suspension.RemoveControlArmModel(self: Suspension, model: Model)
	assert(model:IsA("Model"), "Expected model to be a Model")

	for i, controlArm in ipairs(self._controlArms) do
		if controlArm.model == model then
			table.remove(self._controlArms, i)
			return
		end
	end

	warn(`WheelVehicleSuspension:RemoveControlArmModel: No control arm found for model {model.Name}.`)
end

function Suspension.ApplyLowerStrutModel(self: Suspension, model: Model)
	assert(model:IsA("Model"), "Expected model to be a Model")
	assert(model.PrimaryPart, "Expected model to have a PrimaryPart")

	local attachment = assert(
		model.PrimaryPart:FindFirstChild("WeldAttachment"),
		"Expected model to have a WeldAttachment in its PrimaryPart"
	)

	local rigidConstraint = Instance.new("RigidConstraint")
	rigidConstraint.Name = "LowerStrutConstraint"
	rigidConstraint.Attachment0 = self._links.bottomLink
	rigidConstraint.Attachment1 = attachment
	rigidConstraint.Parent = model

	return rigidConstraint
end

function Suspension.ApplyUpperStrutModel(self: Suspension, model: Model)
	assert(model:IsA("Model"), "Expected model to be a Model")
	assert(model.PrimaryPart, "Expected model to have a PrimaryPart")

	local attachment = assert(
		model.PrimaryPart:FindFirstChild("WeldAttachment"),
		"Expected model to have a WeldAttachment in its PrimaryPart"
	)

	local rigidConstraint = Instance.new("RigidConstraint")
	rigidConstraint.Name = "UpperStrutConstraint"
	rigidConstraint.Attachment0 = self._links.topLink
	rigidConstraint.Attachment1 = attachment
	rigidConstraint.Parent = model

	return rigidConstraint
end

function Suspension.AnimateComponents(self: Suspension, deltaTimeSim: number)
	for _, controlArm in ipairs(self._controlArms) do
		if controlArm.movementType == "Motor6D" then
			controlArm.motor.DesiredAngle = self._controlArmAngle * controlArm.angleFactor
		end
	end
end

-- Suspension.__newindex = function(self, key, value)
-- 	if key == "currentHeight" then
-- 		rawset(self, key, math.clamp(value, -self.maxHeight or 0, self.maxHeight or 0))
-- 	else
-- 		rawset(self, key, value)
-- 	end
-- end

return Suspension
