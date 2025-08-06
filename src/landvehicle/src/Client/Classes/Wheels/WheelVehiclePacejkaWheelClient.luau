--[=[
    Simulate a Pacejka tire model on a wheel-based vehicle.

	See http://www-cdr.stanford.edu/dynamic/bywire/tires.pdf.
	Used as reference for this implementation.

	TODO: Massive simplifications and optimisations are possible once everything is finalised.

    @client
    @class WheelVehiclePacejkaWheelClient
]=]

local require = require(script.Parent.loader).load(script)

local AttributeValue = require("AttributeValue")
local DebugAnnotationConstants = require("DebugAnnotationConstants")
local WheelVehicleTypes = require("WheelVehicleTypes")
local WheelVehicleUtils = require("WheelVehicleUtils")
local WheelVehicleWheelClient = require("WheelVehicleWheelClient")

local N_TO_ROWTONS = 0.163
local RMU_TO_KG = 21.952

local PI = math.pi
local TWO_PI = PI * 2
local sin = math.sin
local atan = math.atan
local atan2 = math.atan2
local abs = math.abs
local min = math.min
local exp = math.exp
local deg = math.deg
local sign = math.sign
local euler = exp(1)

local PacejkaWheel = setmetatable({}, WheelVehicleWheelClient)
PacejkaWheel.ClassName = "PacejkaWheel"
PacejkaWheel.__index = PacejkaWheel

export type PacejkaWheel =
	typeof(setmetatable(
		{} :: { vehicleMass: number, _torqueToCarForceRatio: number },
		{} :: typeof({ __index = PacejkaWheel })
	))
	& WheelVehicleWheelClient.Wheel

function PacejkaWheel.new(
	wheelObj: BasePart,
	wheelConfig: WheelVehicleTypes.WheelConfig,
	links: WheelVehicleUtils.Links,
	forceAttachment: Attachment,
	vehicleMass: number
): PacejkaWheel
	local self = setmetatable(WheelVehicleWheelClient.new(wheelObj, wheelConfig, links, forceAttachment), PacejkaWheel)

	self.vehicleMass = vehicleMass

	self:SetConstants()

	AttributeValue.new(self._obj, DebugAnnotationConstants.NAMES.ENABLE_ANNOTATIONS, false)
		:Observe()
		:Subscribe(function(enabled: boolean)
			if enabled then
				self._debugGui = Instance.new("BillboardGui")
				self._debugGui.Size = UDim2.new(0, 200, 0, 50)
				self._debugGui.AlwaysOnTop = true
				self._debugGui.Parent = self._obj

				self._slipAngleText = Instance.new("TextLabel")
				self._slipAngleText.Size = UDim2.new(1, 0, 1, 0)
				self._slipAngleText.BackgroundTransparency = 1
				self._slipAngleText.TextColor3 = Color3.new(1, 1, 1)
				self._slipAngleText.TextStrokeTransparency = 0
				self._slipAngleText.TextSize = 16
				self._slipAngleText.Parent = self._debugGui

				self._maid.debugGui = function()
					self._debugGui:Destroy()
					self._debugGui = nil
					self._slipAngleText = nil
				end
			else
				self._maid.debugGui = nil
			end
		end)

	return self
end

function PacejkaWheel.SetConstants(self: PacejkaWheel)
	WheelVehicleWheelClient.SetConstants(self)

	local wheelInertia = 1 / 2 * self.mass * self.radius ^ 2
	self._torqueToCarForceRatio = (wheelInertia / self.radius ^ 2) / (self.vehicleMass + wheelInertia / self.radius ^ 2)
end

function PacejkaWheel.UpdateStepped(
	self: PacejkaWheel,
	deltaTimeSim: number,
	verticalForce: number,
	contactNormal: Vector3
)
	debug.profilebegin("WheelVehiclePacejkaWheelClient:UpdateStepped")

	local wheelGlobalOrientation = self._wheelLink.WorldOrientation
	local velocityGlobal = self._obj.Velocity

	-- NOTE: Remember for whatever strange reason, the negative Z axis is the forward direction in Roblox.
	-- Here: -Z -> backward, +X -> left
	local velocityRelative = CFrame.fromOrientation(
		math.rad(wheelGlobalOrientation.X),
		math.rad(wheelGlobalOrientation.Y),
		math.rad(wheelGlobalOrientation.Z)
	):VectorToObjectSpace(velocityGlobal) -- * CFrame.lookAt(Vector3.new(0, 0, 0), -velocityGlobal.Unit):Inverse()

	-- Do nothing if NaN velocity.
	local longitudeVelocity = -velocityRelative.Z
	-- local deltaLongitudeVelocity = longitudeVelocity - self._previousLongitudeVelocity
	-- self._previousLongitudeVelocity = longitudeVelocity

	local lateralVelocity = velocityRelative.X

	local speed = Vector2.new(lateralVelocity, longitudeVelocity).Magnitude

	if not (longitudeVelocity == longitudeVelocity) then
		return
	end

	local torque = self.baseTorque -- +ve when accelerating, -ve when braking
	local lateralForce = 0
	local longitudinalForce = 0
	local longitudinalSlip = longitudeVelocity - self.angularVelocity * self.radius -- -ve when accelerating, +ve when braking.

	-- Pacejka mysterious and magical constants.
	-- See http://www-cdr.stanford.edu/dynamic/bywire/tires.pdf.
	-- And also https://www.desmos.com/calculator/g3aksyrypt.
	if verticalForce > 0 then
		local camberAngle = 90 - deg(atan2(contactNormal.Y, contactNormal.X))
		local slipAngle = deg(atan2(lateralVelocity, longitudeVelocity))
		if abs(slipAngle) > 90 then
			slipAngle = abs(180 - slipAngle) * sign(slipAngle)
		end
		local percentLongitudinalSlip = 0

		-- In kN btw.
		local Fz = (verticalForce / workspace.gravity + self.mass) * RMU_TO_KG * 9.81 / 1000 -- Make Roblox class gravity be the same as real world.

		-- Lateral force component (F_y -> Fy)
		local FyC = 1.30
		local FyD = -22.1 * Fz ^ 2 + 1011 * Fz
		local FyBCD = 1078 * sin(1.82 * atan(0.208 * Fz))
		local FyB = FyBCD / (FyC * FyD)
		local FyE = 0 * Fz ^ 2 - 0.354 * Fz + 0.707

		-- Lateral force camber angle factor
		local FySh = 0.028 * camberAngle
		local FySv = (0 * Fz ^ 2 + 14.8 * Fz) * camberAngle
		FyB += -0.022 * abs(camberAngle) * FyB

		-- Lateral force component continued
		local FyPhi = (1 - FyE) * (slipAngle + FySh) + (FyE / FyB) * atan(FyB * (slipAngle + FySh))
		lateralForce = (FyD * sin(FyC * atan(FyB * FyPhi)) + FySv) * N_TO_ROWTONS

		-- lateralForce *= min(1, abs(speed) * 0.22) -- To deal with low speed slip angles.
		lateralForce *= min(1, abs(speed) * 0.04) -- To deal with low speed slip angles.

		-- Longitudinal force component (F_x -> Fx)
		if longitudeVelocity ~= 0 then
			if abs(longitudeVelocity) > 15 then
				percentLongitudinalSlip = longitudinalSlip / abs(longitudeVelocity) * 100
			else
				percentLongitudinalSlip = longitudinalSlip * 0.4
				-- print("calculating small", percentLongitudinalSlip)
			end

			local FxC = 1.65
			local FxD = -21.3 * Fz ^ 2 + 1144 * Fz
			local FxBCD = (49.6 * Fz ^ 2 + 226 * Fz) / (euler ^ (0.069 * Fz))
			local FxB = FxBCD / (FxC * FxD)
			local FxE = -0.006 * Fz ^ 2 + 0.056 * Fz + 0.486
			local FxPhi = (1 - FxE) * percentLongitudinalSlip + (FxE / FxB) * atan(FxB * percentLongitudinalSlip)
			longitudinalForce = (FxD * sin(FxC * atan(FxB * FxPhi))) * N_TO_ROWTONS
			-- longitudinalForce *= min(1, abs(speed) * 0.15) -- To deal with low speed slip angles.
		end

		-- Distribute the net longitudinal force between car acceleration and the wheel torque.
		-- A very lazy fix for when the vehicle comes to a sudden stop due to e.g. a collision.
		-- TODO: Improve this force distribution.
		if abs(longitudinalSlip) < 6 then
			torque += longitudinalForce * self.radius * self._torqueToCarForceRatio
			longitudinalForce *= (1 - self._torqueToCarForceRatio)
		else
			torque += longitudinalForce * self.radius
		end

		if self._slipAngleText then
			self._slipAngleText.Text = string.format(
				"Vert Force: %.2fkN\nSlip Angle: %.2f\nLongitudinal Slip: %.2f%%",
				Fz,
				slipAngle,
				percentLongitudinalSlip
			)
		end

		if self._obj:GetAttribute("Position") == "FL" then
			-- print("torque", torque, longitudinalForce)
			-- print(min(1, abs(speed) * 0.22), lateralForce)
			-- print(Fz)
			-- print((FyD * sin(FyC * atan(FyB * FyPhi)) + FySv), Fz)
			-- print((longitudeVelocity - self.angularVelocity * self.radius), torque)
			print(self.angularVelocity, torque, longitudinalForce, self._torqueToCarForceRatio)
			print("-")
		end
	end

	-- TODO: Implement better rolling resistance
	torque -= self.angularVelocity * deltaTimeSim * 10

	-- Deal with excessive angular velocity correction.
	-- NOTE: 06/08/2025 - too sick today to fix this :(
	-- if
	-- 	abs(longitudinalSlip) > 1
	-- 	and sign(longitudinalSlip / self.radius + torque * deltaTimeSim) ~= sign(longitudinalSlip)
	-- then
	-- 	torque = -longitudinalSlip / deltaTimeSim
	-- 	longitudinalForce = torque / self.radius
	-- 	print("correcting")
	-- end

	-- Wheel rotation
	-- local angularVelocityRelative = longitudeVelocity / self.radius - self.angularVelocity

	self.angularVelocity += torque * deltaTimeSim

	self.rotation += self.angularVelocity * deltaTimeSim
	if (self.rotation :: number) > TWO_PI then
		self.rotation -= TWO_PI
	elseif (self.rotation :: number) < 0 then
		self.rotation += TWO_PI
	end

	-- self.attachment.Orientation = Vector3.new(math.deg(self.rotation), 0, 0)
	self.attachment.CFrame = CFrame.Angles(self.rotation, 0, 0)

	-- TODO: A more advanced traction model required.
	-- local maxTraction = self._config.baseAdhesionCoefficient * verticalForce
	self.force.Force = Vector3.new(-lateralForce, 0, longitudinalForce)

	debug.profileend()
end

return PacejkaWheel
