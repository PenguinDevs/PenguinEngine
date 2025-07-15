--!strict
--[=[
	Initialises vehicle related binders.

	@server
	@class VehicleService
]=]

local require = require(script.Parent.loader).load(script)

local ServiceBag = require("ServiceBag")

local VehicleService = {}
VehicleService.ServiceName = "VehicleService"

--[[
	Initialises the vehicles service on the server. Should be done via [ServiceBag].
	@param serviceBag ServiceBag
--]]
function VehicleService:Init(serviceBag: ServiceBag.ServiceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")
end

return VehicleService
