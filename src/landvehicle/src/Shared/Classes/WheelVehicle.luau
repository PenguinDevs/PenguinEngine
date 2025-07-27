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

local BaseVehicle = require("BaseVehicle")
local Binder = require("Binder")
local WheelVehicleAssembly = require("WheelVehicleAssembly")
local WheelVehicleConstants = require("WheelVehicleConstants")
local WheelVehicleTypes = require("WheelVehicleTypes")

local WheelVehicle = setmetatable({}, BaseVehicle)
WheelVehicle.ClassName = "WheelVehicle"
WheelVehicle.__index = WheelVehicle

export type WheelVehicle = typeof(setmetatable(
	{} :: {
		_config: WheelVehicleTypes.WheelVehicleConfig,
		_debugAnnotationsConfig: WheelVehicleTypes.WheelVehicleAnnotations?,
	},
	{} :: typeof({ __index = WheelVehicle })
)) & BaseVehicle.BaseVehicle

--[=[
	Constructs a new WheelVehicle. Should be done via [Binder] which is returned by [WheelVehicle].
	@param vehicle Model
	@return WheelVehicle
]=]
function WheelVehicle.new(vehicle: Model): WheelVehicle
	local self = setmetatable(BaseVehicle.new(vehicle), WheelVehicle) :: WheelVehicle

	self._config = WheelVehicleConstants.DEFAULT_CONFIG

	return self
end

--[=[
	Sets the configuration for the vehicle. This should be done before assembling the vehicle.
	@param config WheelVehicleTypes.WheelVehicleConfig -- The vehicle configuration
	@return WheelVehicle -- Returns self for chaining
]=]
function WheelVehicle.SetConfig(self: WheelVehicle, config: WheelVehicleTypes.WheelVehicleConfig): WheelVehicle
	-- TODO: Find a better way to use inheritance and superclass methods.
	BaseVehicle.SetConfig(self, config)

	return self
end

--[=[
	Sets the suspension configuration for the vehicle. This should be done before assembling the vehicle.
	@param customisation WheelVehicleTypes.SuspensionCustomisation -- The vehicle customisation
	@return WheelVehicle -- Returns self for chaining
]=]
function WheelVehicle.ApplyCustomisation(
	self: WheelVehicle,
	customisation: WheelVehicleTypes.WheelVehicleCustomisation
): WheelVehicle
	assert(self._config, "Cannot set customisation without a config first.")

	WheelVehicleAssembly:ApplyCustomisation(self._obj, self._config, customisation)

	return self
end

--[=[
	Assembles the vehicle based on the current configuration.
	Uses the default configuration that is already set in the constructor if a config is not provided.
	@return Model -- The assembled vehicle model with suspension and wheels
]=]
function WheelVehicle.Assemble(self: WheelVehicle): Model
	-- TODO: Find a better way to use inheritance and superclass methods.
	BaseVehicle.Assemble(self)
	return WheelVehicleAssembly:Assemble(
		self._obj,
		self._model,
		self._debugAnnotations,
		self._config,
		self._debugAnnotationsConfig
	)
end

--[=[
	Sets the debug annotations for the vehicle. This should be done before assembling the vehicle.
	@param annotations WheelVehicleTypes.WheelVehicleAnnotations -- The debug annotations for the vehicle
]=]
function WheelVehicle.SetDebugAnnotations(
	self: WheelVehicle,
	annotations: WheelVehicleTypes.WheelVehicleAnnotations
): WheelVehicle
	-- TODO: Find a better way to use inheritance and superclass methods.
	BaseVehicle.SetDebugAnnotations(self, annotations)

	return self
end

--[=[
	Assigns a model to the vehicle. This should be done before assembling the vehicle.
	@param model Model -- The model to assign to the vehicle
	@return WheelVehicle -- Returns self for chaining
]=]
function WheelVehicle.AssignModel(self: WheelVehicle, model: Model): WheelVehicle
	BaseVehicle.AssignModel(self, model)

	return self
end

--[=[
	Applies a model to the vehicle. This should be done before assembling the vehicle and after assigning a model.
	@return WheelVehicle -- Returns self for chaining
]=]
function WheelVehicle.ApplyModel(self: WheelVehicle): WheelVehicle
	-- TODO: Find a better way to use inheritance and superclass methods.
	BaseVehicle.ApplyModel(self)

	return self
end

return Binder.new("WheelVehicle", WheelVehicle)
