--!strict
--[=[
	Initialises vehicle related binders.

	@server
	@class VehiclesService
]=]

local require = require(script.Parent.loader).load(script)

local ServiceBag = require("ServiceBag")

local VehiclesService = {}
VehiclesService.ServiceName = "VehiclesService"

--[[
	Initialises the vehicles service on the server. Should be done via [ServiceBag].
	@param serviceBag ServiceBag
--]]
function VehiclesService:Init(serviceBag: ServiceBag.ServiceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")

	-- Binders
	self._serviceBag:GetService(require("Vehicle"))
end

return VehiclesService
