--[=[
	Base class for vehicles.

	@class BaseVehicle
]=]

local require = require(script.Parent.loader).load(script)

local AttributeValue = require("AttributeValue")
local BaseObject = require("BaseObject")
local ServiceBag = require("ServiceBag")
local VehicleConstants = require("VehicleConstants")

local BaseVehicle = setmetatable({}, BaseObject)
BaseVehicle.ClassName = "BaseVehicle"
BaseVehicle.__index = BaseVehicle

export type BaseVehicle =
	typeof(setmetatable(
		{} :: { debugAnnotations: {}, _hasAssembled: AttributeValue.AttributeValue<boolean> },
		{} :: typeof({ __index = BaseVehicle })
	))
	& BaseObject.BaseObject

--[=[
	Constructs a new BaseVehicle.
	@param vehicle Model
	@param _serviceBag ServiceBag
	@return BaseVehicle
]=]
function BaseVehicle.new(vehicle: Model, _serviceBag: ServiceBag.ServiceBag): BaseVehicle
	assert(vehicle, "Not a Model")
	assert(vehicle.PrimaryPart, "BaseVehicle must have a PrimaryPart")
	assert(vehicle.PrimaryPart:IsA("BasePart"), "BaseVehicle PrimaryPart must be a BasePart")

	local self = setmetatable(BaseObject.new(vehicle), BaseVehicle)

	self:_setupPrimaryPart(self._obj.PrimaryPart)
	vehicle.ModelStreamingMode = Enum.ModelStreamingMode.Atomic

	self._hasAssembled = AttributeValue.new(vehicle, "HasAssembled", false)

	self._debugAnnotations = {}

	return self
end

function BaseVehicle:_setupPrimaryPart(basePart: BasePart)
	basePart.Name = "PrimaryPart"
	basePart.CastShadow = false
	basePart.Transparency = 0.5
	basePart.Color = VehicleConstants.PRIMARY_PART_COLOUR
	basePart.Material = Enum.Material.Neon
	basePart.EnableFluidForces = false
	basePart.CanCollide = false
	basePart.CanTouch = false
	basePart.CanQuery = false
	basePart.Massless = true
	basePart.FrontSurface = Enum.SurfaceType.Hinge
end

--[=[
	Sets the configuration for the vehicle. This should be done before assembling the vehicle.
	Should be overriden to assign the config typing.
	@param config any -- The vehicle configuration
	@return BaseVehicle -- Returns self for chaining
]=]
function BaseVehicle:SetConfig(config: any): BaseVehicle
	if self._hasAssembled.Value then
		error("Cannot change the config of a BaseVehicle after it has already been assembled.")
	end

	self._config = config

	return self
end

--[=[
	Assembles the vehicle based on the current configuration.
	Uses the default configuration that is already set in the constructor if a config is not provided.
	@return Model -- The assembled vehicle model with suspension and wheels
]=]
function BaseVehicle:Assemble(): Model
	assert(self._config, "Cannot assemble a BaseVehicle without a config.")
	if self._hasAssembled.Value then
		error("Cannot change the config of a BaseVehicle after it has already been assembled.")
	end

	self._hasAssembled.Value = true

	return self._obj
end

--[=[
	Applies a model to the vehicle. This should be done before assembling the vehicle.
	@param model Model -- The model to apply
	@return BaseVehicle -- Returns self for chaining
]=]
function BaseVehicle:ApplyModel(model: Model): BaseVehicle
	if self._hasAssembled.Value then
		error("Cannot change the model of a BaseVehicle after it has already been assembled.")
	end

	self._model = model

	return self
end

--[=[
	Sets the debug annotations for the vehicle. This should be done before assembling the vehicle.
	Should be overriden to assign the annotations typing.
	@param annotations any -- The debug annotations for the vehicle
]=]
function BaseVehicle:SetDebugAnnotations(annotations: any): BaseVehicle
	if self._hasAssembled.Value then
		error("Cannot change the debug annotations of a BaseVehicle after it has already been assigned.")
	end

	self._debugAnnotationsConfig = annotations

	return self
end

function BaseVehicle:ShowDebugAnnotations()
	for _, annotation in ipairs(self._debugAnnotations) do
		annotation:SetAttribute("EnableAnnotations", true)
	end
end

function BaseVehicle:HideDebugAnnotations()
	for _, annotation in ipairs(self._debugAnnotations) do
		annotation:SetAttribute("EnableAnnotations", false)
	end
end

function BaseVehicle:GetObj(): Model
	return self._vehicle
end

return BaseVehicle
