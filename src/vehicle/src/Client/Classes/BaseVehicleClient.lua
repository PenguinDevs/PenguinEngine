--[=[
	Base class for vehicles.

	@server
	@class BaseVehicleClient
]=]

local require = require(script.Parent.loader).load(script)

local BaseObject = require("BaseObject")
local ServiceBag = require("ServiceBag")

local BaseVehicleClient = setmetatable({}, BaseObject)
BaseVehicleClient.ClassName = "BaseVehicleClient"
BaseVehicleClient.__index = BaseVehicleClient

export type BaseVehicleClient =
	typeof(setmetatable({} :: {}, {} :: typeof({ __index = BaseVehicleClient })))
	& BaseObject.BaseObject

--[=[
	Constructs a new BaseVehicleClient.
	@param vehicle Model
	@param _serviceBag ServiceBag
	@return BaseVehicleClient
]=]
function BaseVehicleClient.new(vehicle: Model, _serviceBag: ServiceBag.ServiceBag): BaseVehicleClient
	assert(vehicle, "Not a Model")
	assert(vehicle.PrimaryPart, "BaseVehicleClient must have a PrimaryPart")
	assert(vehicle.PrimaryPart:IsA("BasePart"), "BaseVehicleClient PrimaryPart must be a BasePart")

	local self = setmetatable(BaseObject.new(vehicle), BaseVehicleClient)

	return self
end

return BaseVehicleClient
