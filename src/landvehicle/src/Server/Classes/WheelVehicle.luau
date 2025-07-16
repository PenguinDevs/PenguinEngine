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
local WheelVehicleAssembly = require("WheelVehicleAssembly")
local WheelVehicleConstants = require("WheelVehicleConstants")
local WheelVehicleTypes = require("WheelVehicleTypes")

local WheelVehicle = setmetatable({}, BaseVehicle)
WheelVehicle.ClassName = "WheelVehicle"
WheelVehicle.__index = WheelVehicle

export type WheelVehicle = typeof(setmetatable(
	{} :: {
		_vehicle: Model,
		_config: WheelVehicleTypes.WheelVehicleConfig,
		_hasAssembled: AttributeValue.AttributeValue<boolean>,
		_debugAnnotations: WheelVehicleTypes.WheelVehicleAnnotations?,
	},
	{} :: typeof({ __index = WheelVehicle })
))

--[=[
	Constructs a new WheelVehicle. Should be done via [Binder] which is returned by [WheelVehicle].
	@param vehicle Model
	@param _serviceBag ServiceBag
	@return WheelVehicle
]=]
function WheelVehicle.new(vehicle: Model, _serviceBag: ServiceBag.ServiceBag): WheelVehicle
	local self = setmetatable(BaseVehicle.new(vehicle), WheelVehicle)

	self._vehicle = vehicle
	self._config = WheelVehicleConstants.DEFAULT_CONFIG
	self._hasAssembled = AttributeValue.new(vehicle, "HasAssembled", false)

	return self
end

--[=[
	Sets the configuration for the vehicle. This should be done before assembling the vehicle.
	@param config WheelVehicleTypes.WheelVehicleConfig -- The vehicle configuration
	@return WheelVehicle -- Returns self for chaining
]=]
function WheelVehicle:SetConfig(config: WheelVehicleTypes.WheelVehicleConfig): WheelVehicle
	if self._hasAssembled.Value then
		error("Cannot change the config of a WheelVehicle after it has already been assembled.")
	end

	self._config = config

	return self
end

--[=[
	Assembles the vehicle based on the current configuration.
	Uses the default configuration that is already set in the constructor if a config is not provided.
	@return Model -- The assembled vehicle model with suspension and wheels
]=]
function WheelVehicle:Assemble(): Model
	assert(self._config, "Cannot assemble a WheelVehicle without a config.")
	if self._hasAssembled.Value then
		error("Cannot change the config of a WheelVehicle after it has already been assembled.")
	end

	self._hasAssembled.Value = true

	return WheelVehicleAssembly.assemble(self._vehicle, self._config, self._debugAnnotations)
end

--[=[
	Sets the debug annotations for the vehicle. This should be done before assembling the vehicle.
	@param annotations WheelVehicleTypes.WheelVehicleAnnotations -- The debug annotations for the vehicle
]=]
function WheelVehicle:SetDebugAnnotations(annotations: WheelVehicleTypes.WheelVehicleAnnotations): WheelVehicle
	if self._hasAssembled.Value then
		error("Cannot change the debug annotations of a WheelVehicle after it has already been assigned.")
	end

	self._debugAnnotations = annotations

	return self
end

return Binder.new("WheelVehicle", WheelVehicle)
