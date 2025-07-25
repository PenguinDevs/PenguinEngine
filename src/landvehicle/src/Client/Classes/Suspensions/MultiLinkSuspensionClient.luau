--[=[
    Multi-link suspension client class

    @client
    @class MultiLinkSuspensionClient
]=]

local require = require(script.Parent.loader).load(script)

local WheelVehicleSuspensionClient = require("WheelVehicleSuspensionClient")
local WheelVehicleTypes = require("WheelVehicleTypes")

local MultiLinkSuspension = setmetatable({}, WheelVehicleSuspensionClient)
MultiLinkSuspension.ClassName = "MultiLinkSuspensionClient"
MultiLinkSuspension.__index = MultiLinkSuspension

export type MultiLinkSuspension =
	typeof(setmetatable({} :: { _radius: number }, {} :: typeof({ __index = MultiLinkSuspension })))
	& WheelVehicleSuspensionClient.SuspensionClient

local function camberCurve(maxCamber: number, height: number, maxHeight: number): number
	local normalizedHeight = height / maxHeight

	-- Simple multi-link approximation: mostly linear with slight curve
	local camberGain = maxCamber * normalizedHeight * (1 + 0.2 * normalizedHeight ^ 2)

	return math.rad(-camberGain)
end

function MultiLinkSuspension.new(vehicleObj: Model, config: WheelVehicleTypes.SuspensionConfig): MultiLinkSuspension
	local self =
		setmetatable(WheelVehicleSuspensionClient.new(vehicleObj, config), MultiLinkSuspension) :: MultiLinkSuspension

	self._radius = (self._links.pivotLink.WorldPosition - self._links.wheelLink.WorldPosition).Magnitude

	self._initialMidLinkCFrame = self._links.midLink.CFrame

	return self
end

function MultiLinkSuspension:UpdateStepped(deltaTimeSim: number)
	if not WheelVehicleSuspensionClient.UpdateStepped(self) then
		return
	end

	self.currentHeight = tick() / 6 % (self.maxHeight * 2) - self.maxHeight

	local angle = math.asin(self.currentHeight / self._radius)

	self._links.midLink.CFrame = self._initialMidLinkCFrame
		* self._links.bottomLink.CFrame
		* self._links.wheelLink.CFrame
		* CFrame.new(self._sign * (self._radius - math.cos(angle) * self._radius), self.currentHeight, 0)
		* CFrame.Angles(
			0,
			0,
			self._sign * camberCurve(self._config.suspension.camberGain, self.currentHeight, self.maxHeight)
		)
		* (self._links.bottomLink.CFrame * self._links.wheelLink.CFrame):Inverse()

	-- TODO: Faster alternative but less accurate, to be compared again later.
	-- local xOffset = self._radius * (1 - math.cos(angle)) * self._sign
	-- local camberAngle = self._sign * camberCurve(self._config.suspension.camberGain, self.currentHeight, self.maxHeight)

	-- -- Apply transformation directly to the initial CFrame
	-- self._links.midLink.CFrame = self._initialMidLinkCFrame
	-- 	* CFrame.new(0, -xOffset, self.currentHeight)
	-- 	* CFrame.Angles(camberAngle, 0, 0)
end

function MultiLinkSuspension:Destroy() end

return MultiLinkSuspension
