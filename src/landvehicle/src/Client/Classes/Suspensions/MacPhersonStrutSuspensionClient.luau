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

local function camberCurve(maxCamber: number, height: number, maxHeight: number): number
	-- See https://www.desmos.com/calculator/udglwe5hli

	local zeroCamberAt = maxHeight * 0.8

	if height > 0 then
		return math.rad(maxCamber * (4 / (zeroCamberAt ^ 2)) * height * (height - zeroCamberAt))
	else
		return math.rad(maxCamber * math.sqrt(-height * 4 / zeroCamberAt))
	end
end

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

	self.currentHeight = tick() / 6 % (self.maxHeight * 2) - self.maxHeight

	local angle = math.asin(self.currentHeight / self._radius)

	self._links.midLink.CFrame = self._initialMidLinkCFrame
		* self._links.bottomLink.CFrame
		* self._links.wheelLink.CFrame
		* CFrame.new(-math.cos(angle) * self._radius + self._radius, self.currentHeight, 0)
		* CFrame.Angles(0, 0, camberCurve(self._config.suspension.camberGain, self.currentHeight, self.maxHeight))
		* (self._links.bottomLink.CFrame * self._links.wheelLink.CFrame):Inverse()

	print(
		"Camber: ",
		math.deg(camberCurve(self._config.suspension.camberGain, self.currentHeight, self.maxHeight)),
		self._config.suspension.camberGain,
		self.currentHeight,
		self.maxHeight
	)
end

function MacPhersonStrutSuspension:Destroy() end

return MacPhersonStrutSuspension
