--!strict
--[=[
	@class VehiclesService
]=]

local require = require(script.Parent.loader).load(script)

local ServiceBag = require("ServiceBag")

local VehiclesService = {}
VehiclesService.ServiceName = "VehiclesService"

function VehiclesService:Init(serviceBag: ServiceBag.ServiceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")


end

return VehiclesService