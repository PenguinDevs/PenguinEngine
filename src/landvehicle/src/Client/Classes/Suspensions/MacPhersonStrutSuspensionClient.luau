--[=[
    MacPherson strut suspension client class

    @client
    @class MacPhersonStrutSuspensionClient
]=]

local require = require(script.Parent.loader).load(script)

local WheelVehicleSuspensionClient = require("WheelVehicleSuspensionClient")
local WheelVehicleTypes = require("WheelVehicleTypes")

local MacPhersonStrutSuspension = setmetatable({}, WheelVehicleSuspensionClient)
MacPhersonStrutSuspension.ClassName = "MacPhersonStrutSuspensionClient"
MacPhersonStrutSuspension.__index = MacPhersonStrutSuspension

export type MacPhersonStrutSuspension =
	typeof(setmetatable({} :: { _radius: number }, {} :: typeof({ __index = MacPhersonStrutSuspension })))
	& WheelVehicleSuspensionClient.Suspension

local function camberCurve(maxCamber: number, height: number, maxHeight: number): number
	-- See https://www.desmos.com/calculator/udglwe5hli
	-- TODO: Derive an approximate fast formula from https://www.researchgate.net/publication/324517802_Kinematic_and_Dynamic_Analysis_for_a_New_MacPherson_Strut_Suspension_System for a more accurate formula.

	local zeroCamberAt = maxHeight * 0.8

	if height > 0 then
		return math.rad(maxCamber * (4 / (zeroCamberAt ^ 2)) * height * (height - zeroCamberAt))
	else
		return math.rad(maxCamber * math.sqrt(-height * 4 / zeroCamberAt))
	end
end

function MacPhersonStrutSuspension.new(
	vehicleObj: Model,
	config: WheelVehicleTypes.SuspensionConfig
): MacPhersonStrutSuspension
	local self =
		setmetatable(WheelVehicleSuspensionClient.new(vehicleObj, config), MacPhersonStrutSuspension) :: MacPhersonStrutSuspension

	self._radius = (self._links.pivotLink.WorldPosition - self._links.wheelLink.WorldPosition).Magnitude

	self._initialMidLinkCFrame = self._links.midLink.CFrame

	return self
end

function MacPhersonStrutSuspension.UpdateStepped(self: MacPhersonStrutSuspension, deltaTimeSim: number)
	debug.profilebegin("MacPhersonStrutSuspension:UpdateStepped")

	WheelVehicleSuspensionClient.UpdateStepped(self, deltaTimeSim)

	local wheelLinkOffset = self._links.bottomLink.CFrame * self._links.wheelLink.CFrame

	self._links.midLink.CFrame = self._initialMidLinkCFrame
		* wheelLinkOffset
		* CFrame.new(self._sign * (self._radius - math.cos(self._angle) * self._radius), self.currentHeight, 0)
		* CFrame.Angles(
			0,
			0,
			self._sign * camberCurve(self._config.suspension.camberGain, self.currentHeight, self.maxHeight)
		)
		* wheelLinkOffset:Inverse()

	-- TODO: Faster alternative but less accurate, to be compared again later.
	-- local xOffset = self._radius * (1 - math.cos(angle)) * self._sign
	-- local camberAngle = self._sign * camberCurve(self._config.suspension.camberGain, self.currentHeight, self.maxHeight)

	-- -- Apply transformation directly to the initial CFrame
	-- self._links.midLink.CFrame = self._initialMidLinkCFrame
	-- 	* CFrame.new(0, -xOffset, self.currentHeight)
	-- 	* CFrame.Angles(camberAngle, 0, 0)

	debug.profileend()
end

return MacPhersonStrutSuspension
