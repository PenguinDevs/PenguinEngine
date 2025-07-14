--!strict
--[=[
	@class VehiclesServiceClient
]=]

local require = require(script.Parent.loader).load(script)

local ServiceBag = require("ServiceBag")

local VehiclesServiceClient = {}
VehiclesServiceClient.ServiceName = "VehiclesServiceClient"

function VehiclesServiceClient:Init(serviceBag: ServiceBag.ServiceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")


end

return VehiclesServiceClient