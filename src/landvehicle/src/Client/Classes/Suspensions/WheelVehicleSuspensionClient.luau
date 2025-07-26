--[=[
    Suspension movement.

	@client
    @class WheelVehicleSuspensionClient
]=]

local require = require(script.Parent.loader).load(script)

local RunService = game:GetService("RunService")

local BaseObject = require("BaseObject")
local WheelVehicleConstants = require("WheelVehicleConstants")
local WheelVehicleTypes = require("WheelVehicleTypes")
local WheelVehicleUtils = require("WheelVehicleUtils")

SUSPENSION_UPDATE_RATE = 0.2 -- seconds
MAX_HEIGHT_PERCENTAGE = 0.8

local SuspensionClient = setmetatable({}, BaseObject)
SuspensionClient.ClassName = "SuspensionClient"
SuspensionClient.__index = SuspensionClient

export type SuspensionClient = typeof(setmetatable(
	{} :: {
		_config: WheelVehicleTypes.SuspensionConfig,
		_links: WheelVehicleUtils.Links,
		_lastUpdateTime: number,
		_sign: number,
		currentHeight: number,
		targetHeight: number,
		maxHeight: number,
	},
	{} :: typeof({ __index = SuspensionClient }) & BaseObject.BaseObject
))

function SuspensionClient.new(vehicleObj: Model, config: WheelVehicleTypes.SuspensionConfig)
	assert(vehicleObj:IsA("Model"), "Expected vehicleObj to be a Model")
	assert(vehicleObj.PrimaryPart, "Expected vehicleObj to have a PrimaryPart")
	-- local wheelsFolder = vehicleObj:FindFirstChild("Wheels")
	-- assert(wheelsFolder, "Expected vehicleObj to have Wheels child")

	local links = WheelVehicleUtils:GetLinks(vehicleObj, config.position)

	local self = setmetatable(BaseObject.new(links.topLink), SuspensionClient) :: BaseObject.BaseObject

	self._config = config
	self._links = links
	self._lastUpdateTime = 0

	if config.position:sub(2, 2) == WheelVehicleConstants.POSITIONS.LEFT then
		self._sign = 1
	else
		self._sign = -1
	end

	self.currentHeight = 0
	self.targetHeight = 0
	self.maxHeight = math.abs(self._links.midLink.Position.Z) * MAX_HEIGHT_PERCENTAGE

	-- local wheel = wheelsFolder:FindFirstChild(`Wheel{config.position}`) :: BasePart?
	-- if wheel then
	-- 	wheel.CanCollide = false
	-- end

	return self
end

function SuspensionClient:Start()
	self._maid._updateHeartbeat = RunService.PostSimulation:Connect(function(deltaTimeSim)
		self:UpdateStepped(deltaTimeSim)
	end)
end

function SuspensionClient:Stop()
	self._maid._updateHeartbeat = nil
end

function SuspensionClient:UpdateStepped(deltaTimeSim: number): boolean
	if tick() - self._lastUpdateTime < SUSPENSION_UPDATE_RATE then
		return false
	end

	return true
end

return SuspensionClient
