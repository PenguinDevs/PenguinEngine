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

	-- External
	self._serviceBag:GetService(require("DebugAnnotationService"))
	self._serviceBag:GetService(require("SettingsInputKeyMapService"))

	-- Binders
	self._serviceBag:GetService(require("WheelVehicle"))

	-- Input Key Maps
	self._seatInputKeyMap = self._serviceBag:GetService(require("WheelVehicleSeatInputKeyMap"))
end

return LandVehicleService
