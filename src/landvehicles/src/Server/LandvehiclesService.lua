--!strict
--[=[
	@class LandvehiclesService
]=]

local require = require(script.Parent.loader).load(script)

local ServiceBag = require("ServiceBag")

local LandvehiclesService = {}
LandvehiclesService.ServiceName = "LandvehiclesService"

function LandvehiclesService:Init(serviceBag: ServiceBag.ServiceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")


end

return LandvehiclesService