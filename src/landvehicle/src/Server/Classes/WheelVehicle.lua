--[=[
	Base class for wheel-based vehicles such as sedans, meant to be used with binders.
    This class exports a [Binder].
	While a vehicle model is bound with this class, it is considered a vehicle.

	:::tip
	Initialise this whole system through [LandVehicleService].
	:::

	```lua
	-- Be sure to do the service init on the client too
	local ServiceBag = require("ServiceBag")
	local WheelVehicle = require("WheelVehicle")

	local serviceBag = ServiceBag.new()
	serviceBag:GetService(require("LandVehicleService"))

	serviceBag:Init()
	serviceBag:Start()

	-- Register the part as a vehicle
	WheelVehicle:Tag(part)

	-- Unregister the part as a vehicle
	WheelVehicle:Untag(part)
	```

	@class WheelVehicle
]=]

local require = require(script.Parent.loader).load(script)

local AttributeValue = require("AttributeValue")
local BaseVehicle = require("BaseVehicle")
local Binder = require("Binder")
local ServiceBag = require("ServiceBag")

local WheelVehicle = setmetatable({}, BaseVehicle)
WheelVehicle.ClassName = "WheelVehicle"
WheelVehicle.__index = WheelVehicle

--[=[
	Constructs a new WheelVehicle. Should be done via [Binder] which is returned by [WheelVehicle].
	@param vehicle Model
	@param _serviceBag ServiceBag
	@return WheelVehicle
]=]
function WheelVehicle.new(vehicle: Model, _serviceBag: ServiceBag.ServiceBag)
	local self = setmetatable(BaseVehicle.new(vehicle, _serviceBag), WheelVehicle)

	self._hasAssembled = AttributeValue.new()

	return self
end

function WheelVehicle:_setupPrimaryPart(basePart: BasePart) end

return Binder.new("WheelVehicle", WheelVehicle)
