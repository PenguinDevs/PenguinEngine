--[=[
    Manage driver sitting in a wheel vehicle.

    @client
    @class WheelVehicleDriverClient
]=]

local require = require(script.Parent.loader).load(script)

local ServiceBag = require("ServiceBag")
local WheelVehicleDigitalControllerClient = require("WheelVehicleDigitalControllerClient")
local WheelVehiclePassengerClient = require("WheelVehiclePassengerClient")
local WheelVehicleSuspensionControllerClient = require("WheelVehicleSuspensionControllerClient")

local Driver = {}
Driver.ClassName = "Driver"
Driver.__index = Driver

export type Driver =
	typeof(setmetatable(
		{} :: { _suspensionController: WheelVehicleSuspensionControllerClient.SuspensionController },
		{} :: typeof({ __index = Driver })
	))
	& WheelVehiclePassengerClient.Passenger

function Driver.new(
	vehicleObj: Model,
	_serviceBag: ServiceBag.ServiceBag,
	player: Player,
	exitCallback: () -> (),
	suspensionController: WheelVehicleSuspensionControllerClient.SuspensionController
): Driver
	local self = setmetatable(WheelVehiclePassengerClient.new(vehicleObj, _serviceBag, player, exitCallback), Driver)

	self._suspensionController = suspensionController

	self._maid:GiveTask(
		WheelVehicleDigitalControllerClient.new(vehicleObj, _serviceBag, player, self._suspensionController)
	)

	return self
end

return Driver
