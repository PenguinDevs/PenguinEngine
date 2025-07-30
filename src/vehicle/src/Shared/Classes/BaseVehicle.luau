--[=[
	Base class for vehicles.

	@class BaseVehicle
]=]

local require = require(script.Parent.loader).load(script)

local AttributeValue = require("AttributeValue")
local BaseObject = require("BaseObject")
local DebugAnnotationConstants = require("DebugAnnotationConstants")
local ValueBaseValue = require("ValueBaseValue")
local VehicleConstants = require("VehicleConstants")

local BaseVehicle = setmetatable({}, BaseObject)
BaseVehicle.ClassName = "BaseVehicle"
BaseVehicle.__index = BaseVehicle

export type BaseVehicle = typeof(setmetatable(
	{} :: {
		debugAnnotations: {},
		_hasAssembled: AttributeValue.AttributeValue<boolean>,
		_vehicleModel: Model?,
		_vehicleModelValue: ValueBaseValue.ValueBaseValue,
	},
	{} :: typeof({ __index = BaseVehicle })
)) & BaseObject.BaseObject

--[=[
	Constructs a new BaseVehicle.
	@param vehicle Model
	@return BaseVehicle
]=]
function BaseVehicle.new(vehicle: Model): BaseVehicle
	assert(vehicle, "Not a Model")
	assert(vehicle.PrimaryPart, "BaseVehicle must have a PrimaryPart")
	assert(vehicle.PrimaryPart:IsA("BasePart"), "BaseVehicle PrimaryPart must be a BasePart")

	local self = setmetatable(BaseObject.new(vehicle), BaseVehicle) :: BaseObject.BaseObject

	self:_setupPrimaryPart(self._obj.PrimaryPart)
	vehicle.ModelStreamingMode = Enum.ModelStreamingMode.Atomic

	self._hasAssembled = AttributeValue.new(vehicle, "HasAssembled", false)

	self._vehicleModel = nil

	self._vehicleModelValue = ValueBaseValue.new(self._obj, "ObjectValue", "VehicleModelValue")

	self._debugAnnotations = {}

	return self
end

function BaseVehicle:_setupPrimaryPart(basePart: BasePart)
	basePart.Name = "PrimaryPart"
	basePart.CastShadow = false
	basePart.Transparency = 1
	basePart.Color = VehicleConstants.PRIMARY_PART_COLOUR
	basePart.Material = Enum.Material.Neon
	basePart.EnableFluidForces = false
	basePart.CanCollide = false
	basePart.CanTouch = false
	basePart.CanQuery = false
	basePart.Anchored = true
	basePart.Massless = true
	basePart.FrontSurface = Enum.SurfaceType.Hinge
end

--[=[
	Sets the configuration for the vehicle. This should be done before assembling the vehicle.
	Should be overriden to assign the config typing.
	@param config any -- The vehicle configuration
	@return BaseVehicle -- Returns self for chaining
]=]
function BaseVehicle.SetConfig(self: BaseVehicle, config: any): BaseVehicle
	assert(
		self._hasAssembled.Value == false,
		"Cannot change the config of a BaseVehicle after it has already been assembled."
	)

	self._config = config

	return self
end

--[=[
	Assembles the vehicle based on the current configuration.
	Uses the default configuration that is already set in the constructor if a config is not provided.
	@return Model -- The assembled vehicle model with suspension and wheels
]=]
function BaseVehicle.Assemble(self: BaseVehicle): Model
	assert(self._config, "Cannot assemble a BaseVehicle without a config.")
	assert(self._hasAssembled.Value == false, "Cannot assemble a BaseVehicle that has already been assembled.")

	self._hasAssembled.Value = true

	return self._obj
end

--[=[
	Sets the model for the vehicle.
	@param model Model -- The model to assign to the vehicle
	@return BaseVehicle -- Returns self for chaining
]=]
function BaseVehicle.AssignModel(self: BaseVehicle, model: Model): BaseVehicle
	self._vehicleModelValue.Value = model

	return self
end

function BaseVehicle.ListenToModelChanges(self: BaseVehicle)
	self._vehicleModelValue:Observe():Subscribe(function(model: Model?)
		if self._vehicleModel then
			self._vehicleModel:Destroy()
		end

		if model then
			self._vehicleModel = self:_applyModel(model:Clone())
		end
	end)
end

function BaseVehicle._applyModel(self: BaseVehicle, model: Model): Model
	assert(self._obj.PrimaryPart, "Vehicle must have a PrimaryPart set before applying the model.")

	model.Parent = self._obj

	model:PivotTo(self._obj.PrimaryPart.CFrame)

	local weld = Instance.new("Weld")
	weld.Part0 = self._obj.PrimaryPart
	weld.Part1 = model.PrimaryPart

	weld.Parent = self._obj

	return model
end

function BaseVehicle.StoreDebugAnnotations(self: BaseVehicle)
	for _, obj in pairs(self._obj:GetDescendants()) do
		if obj:GetAttribute(DebugAnnotationConstants.NAMES.ENABLE_ANNOTATIONS) ~= nil then
			table.insert(self._debugAnnotations, obj)
		end
	end
end

--[=[
	Sets the debug annotations for the vehicle. This should be done before assembling the vehicle.
	Should be overriden to assign the annotations typing.
	@param annotations any -- The debug annotations for the vehicle
]=]
function BaseVehicle.SetDebugAnnotations(self: BaseVehicle, annotations: any): BaseVehicle
	assert(
		self._hasAssembled.Value == false,
		"Cannot change the debug annotations of a BaseVehicle after it has already been assigned."
	)

	self._debugAnnotationsConfig = annotations

	return self
end

function BaseVehicle.ShowDebugAnnotations(self: BaseVehicle)
	for _, annotation in ipairs(self._debugAnnotations) do
		annotation:SetAttribute(DebugAnnotationConstants.NAMES.ENABLE_ANNOTATIONS, true)
	end
end

function BaseVehicle.HideDebugAnnotations(self: BaseVehicle)
	for _, annotation in ipairs(self._debugAnnotations) do
		annotation:SetAttribute(DebugAnnotationConstants.NAMES.ENABLE_ANNOTATIONS, false)
	end
end

function BaseVehicle.GetObj(self: BaseVehicle): Model
	return self._obj
end

return BaseVehicle
