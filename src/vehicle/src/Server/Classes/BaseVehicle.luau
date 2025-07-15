--[=[
	Base class for vehicles.

	@server
	@class BaseVehicle
]=]

local require = require(script.Parent.loader).load(script)

local BaseObject = require("BaseObject")
local ServiceBag = require("ServiceBag")
local VehicleConstants = require("VehicleConstants")

local BaseVehicle = setmetatable({}, BaseObject)
BaseVehicle.ClassName = "BaseVehicle"
BaseVehicle.__index = BaseVehicle

export type BaseVehicle = typeof(setmetatable({} :: {}, {} :: typeof({ __index = BaseVehicle }))) & BaseObject.BaseObject

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
	basePart.Anchored = true
	basePart.FrontSurface = Enum.SurfaceType.Hinge
end

return BaseVehicle
