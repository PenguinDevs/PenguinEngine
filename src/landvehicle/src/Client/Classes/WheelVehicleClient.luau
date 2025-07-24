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
local ServiceBag = require("ServiceBag")
local WheelVehicle = require("WheelVehicle")
local WheelVehicleConstants = require("WheelVehicleConstants")
local WheelVehicleTypes = require("WheelVehicleTypes")

local WheelVehicleClient = setmetatable({}, WheelVehicle)
WheelVehicleClient.ClassName = "WheelVehicleClient"
WheelVehicleClient.__index = WheelVehicleClient

export type WheelVehicleClient = typeof(setmetatable(
	{} :: {
		_vehicle: Model,
		_config: WheelVehicleTypes.WheelVehicleConfig,
	},
	{} :: typeof({ __index = WheelVehicleClient })
))

--[=[
	Constructs a new WheelVehicleClient. Should be done via [Binder] which is returned by [WheelVehicleClient].
	@param vehicle Model
	@param _serviceBag ServiceBag
	@return WheelVehicleClient
]=]
function WheelVehicleClient.new(vehicle: Model, _serviceBag: ServiceBag.ServiceBag): WheelVehicleClient
	local self = setmetatable(WheelVehicle.new(vehicle, _serviceBag), WheelVehicleClient)

	self._vehicle = vehicle
	self._config = WheelVehicleConstants.DEFAULT_CONFIG -- TODO: Read from attributes on each component.

	return self
end

return Binder.new("WheelVehicle", WheelVehicleClient)
