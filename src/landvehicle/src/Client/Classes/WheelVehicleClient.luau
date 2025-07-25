--[=[
	Base class for wheel-based vehicles such as sedans, meant to be used with binders.
    This class exports a [Binder].
	While a vehicle model is bound with this class, it is considered a vehicle.

	:::tip
	Initialise this whole system through [LandVehicleServiceClient].
	:::

	```lua
	-- Be sure to do the service init on the server too
	local ServiceBag = require("ServiceBag")
	local WheelVehicleClient = require("WheelVehicleClient")

	local serviceBag = ServiceBag.new()
	serviceBag:GetService(require("LandVehicleServiceClient"))

	serviceBag:Init()
	serviceBag:Start()

	-- Register the part as a vehicle
	WheelVehicleClient:Tag(part)

	-- Unregister the part as a vehicle
	WheelVehicleClient:Untag(part)
	```

    @client
	@class WheelVehicle
]=]

local require = require(script.Parent.loader).load(script)

local Binder = require("Binder")
local MacPhersonStrutSuspensionClient = require("MacPhersonStrutSuspensionClient")
local ServiceBag = require("ServiceBag")
local WheelVehicle = require("WheelVehicle")
local WheelVehicleConfigReader = require("WheelVehicleConfigReader")
local WheelVehicleConstants = require("WheelVehicleConstants")

local WheelVehicleClient = setmetatable({}, WheelVehicle:GetConstructor())
WheelVehicleClient.ClassName = "WheelVehicleClient"
WheelVehicleClient.__index = WheelVehicleClient

export type WheelVehicleClient = typeof(setmetatable(
	{} :: {
		_vehicle: Model,
		_suspensions: {
			frontLeft: MacPhersonStrutSuspensionClient.MacPhersonStrutSuspension?,
			frontRight: MacPhersonStrutSuspensionClient.MacPhersonStrutSuspension?,
			-- rearLeft: WheelVehicleSuspensionClient.SuspensionClient?,
			-- rearRight: WheelVehicleSuspensionClient.SuspensionClient?,
		},
	},
	{} :: typeof({ __index = WheelVehicleClient })
)) & WheelVehicle.WheelVehicle

--[=[
	Constructs a new WheelVehicleClient. Should be done via [Binder] which is returned by [WheelVehicleClient].
	@param vehicle Model
	@param _serviceBag ServiceBag
	@return WheelVehicleClient
]=]
function WheelVehicleClient.new(vehicle: Model, _serviceBag: ServiceBag.ServiceBag): WheelVehicleClient
	local self = setmetatable(WheelVehicleClient, WheelVehicle:GetConstructor()) :: WheelVehicleClient

	self._vehicle = vehicle
	self._config = WheelVehicleConfigReader:Read(vehicle)

	self._suspensions = {
		frontLeft = MacPhersonStrutSuspensionClient.new(vehicle, WheelVehicleConstants.POSITIONS.FRONT_LEFT),
		-- frontRight = MacPhersonStrutSuspensionClient.new(vehicle, WheelVehicleConstants.POSITIONS.FRONT_RIGHT),
		-- rearLeft = WheelVehicleSuspensionClient.new(vehicle, WheelVehicleConstants.POSITIONS.REAR_LEFT),
		-- rearRight = WheelVehicleSuspensionClient.new(vehicle, WheelVehicleConstants.POSITIONS.REAR_RIGHT),
	}

	for _, suspension in pairs(self._suspensions) do
		suspension:Start()
	end

	return self
end

return Binder.new("WheelVehicle", WheelVehicleClient)
