--!strict
--[=[
	@class LandVehiclesServiceClient
]=]

local require = require(script.Parent.loader).load(script)

local ServiceBag = require("ServiceBag")

local LandVehiclesServiceClient = {}
LandVehiclesServiceClient.ServiceName = "LandVehiclesServiceClient"

function LandVehiclesServiceClient:Init(serviceBag: ServiceBag.ServiceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")

	-- Binders
	self._serviceBag:GetService(require("WheelVehicleClient"))
end

return LandVehiclesServiceClient
