--!strict
--[=[
	@class VehicleServiceClient
]=]

local require = require(script.Parent.loader).load(script)

local ServiceBag = require("ServiceBag")

local VehicleServiceClient = {}
VehicleServiceClient.ServiceName = "VehicleServiceClient"

function VehicleServiceClient:Init(serviceBag: ServiceBag.ServiceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")
end

return VehicleServiceClient
