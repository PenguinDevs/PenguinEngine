--[=[
	Base class for vehicles, meant to be used with binders. This class exports a [Binder].
	While a vehicle base part is bound with this class, it is considered a vehicle.

	:::tip
	Initialise this whole system through [VehicleService].
	:::

	```lua
	-- Be sure to do the service init on the client too
	local ServiceBag = require("ServiceBag")
	local Vehicle = require("Vehicle")

	local serviceBag = ServiceBag.new()
	serviceBag:GetService(require("VehicleService"))

	serviceBag:Init()
	serviceBag:Start()

	-- Register the part as a vehicle
	Vehicle:Tag(part)

	-- Unregister the part as a vehicle
	Vehicle:Untag(part)
	```

	@class Vehicle
]=]

local require = require(script.Parent.loader).load(script)

local BaseObject = require("BaseObject")
local Binder = require("Binder")
local ServiceBag = require("ServiceBag")
local VehicleConstants = require("VehicleConstants")

local Vehicle = setmetatable({}, BaseObject)
Vehicle.ClassName = "Vehicle"
Vehicle.__index = Vehicle

--[=[
	Constructs a new Vehicle. Should be done via [Binder] which is returned by [Vehicle].
	@param humanoid Humanoid
	@param _serviceBag ServiceBag
	@return Vehicle
]=]
function Vehicle.new(vehicle: Model, _serviceBag: ServiceBag.ServiceBag)
	assert(vehicle, "Not a Model")
	assert(vehicle.PrimaryPart, "Vehicle must have a PrimaryPart")
	assert(vehicle.PrimaryPart:IsA("BasePart"), "Vehicle PrimaryPart must be a BasePart")

	local self = setmetatable(BaseObject.new(vehicle), Vehicle)

	self:_setupPrimaryPart(self._obj.PrimaryPart)

	return self
end

function Vehicle:_setupPrimaryPart(basePart: BasePart)
	basePart.Name = "PrimaryPart"
	basePart.Transparency = 0.5
	basePart.Color = VehicleConstants.PRIMARY_PART_COLOUR
	basePart.Material = Enum.Material.Neon
	basePart.EnableFluidForces = false
	basePart.CanCollide = false
	basePart.CanTouch = false
	basePart.CanQuery = false
	basePart.Massless = true
	basePart.Anchored = true
end

return Binder.new("Vehicle", Vehicle)
