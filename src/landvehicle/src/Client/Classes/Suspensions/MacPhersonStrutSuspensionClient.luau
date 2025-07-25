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
	& WheelVehicleSuspensionClient.SuspensionClient

function MacPhersonStrutSuspension.new(
	vehicleObj: Model,
	position: WheelVehicleTypes.Positions
): MacPhersonStrutSuspension
	local self =
		setmetatable(WheelVehicleSuspensionClient.new(vehicleObj, position), MacPhersonStrutSuspension) :: MacPhersonStrutSuspension

	self._radius = (self._links.pivotLink.WorldPosition - self._links.wheelLink.WorldPosition).Magnitude

	self._initialMidLinkCFrame = self._links.midLink.CFrame

	return self
end

function MacPhersonStrutSuspension:UpdateStepped(deltaTimeSim: number)
	if not WheelVehicleSuspensionClient.UpdateStepped(self) then
		return
	end

	self.currentHeight = tick() / 6 % 0.8 - 0.4

	local angle = math.asin(self.currentHeight / self._radius)

	self._links.midLink.CFrame = self._initialMidLinkCFrame
		* CFrame.new(0, -math.cos(angle) * self._radius + self._radius, self.currentHeight)
end

function MacPhersonStrutSuspension:Destroy() end

return MacPhersonStrutSuspension
