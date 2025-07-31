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

	-- External
	self._serviceBag:GetService(require("DebugAnnotationServiceClient"))
	self._serviceBag:GetService(require("InputKeyMapServiceClient"))
	self._serviceBag:GetService(require("SettingsInputKeyMapServiceClient"))
	self._inputKeyMapRegistryServiceShared = self._serviceBag:GetService(require("InputKeyMapRegistryServiceShared"))

	-- Binders
	self._serviceBag:GetService(require("WheelVehicleClient"))

	-- Input Key Maps
	self._serviceBag:GetService(require("WheelVehicleSeatInputKeyMap"))
end

return LandVehiclesServiceClient
