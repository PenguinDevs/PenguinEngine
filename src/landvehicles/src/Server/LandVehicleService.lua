--!strict
--[=[
	@class LandVehicleService
]=]

local require = require(script.Parent.loader).load(script)

local ServiceBag = require("ServiceBag")

local LandVehicleService = {}
LandVehicleService.ServiceName = "LandVehicleService"

function LandVehicleService:Init(serviceBag: ServiceBag.ServiceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")
end

return LandVehicleService
