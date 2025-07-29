--[=[
    Simulate wheel on a whel-based vehicle.

    @client
    @class WheelVehicleWheelClient
]=]

local require = require(script.Parent.loader).load(script)

local BaseObject = require("BaseObject")
local WheelVehicleTypes = require("WheelVehicleTypes")

local Wheel = setmetatable({}, BaseObject)
Wheel.ClassName = "Wheel"
Wheel.__index = Wheel

export type Wheel =
	typeof(setmetatable({} :: { _wheelConfig: WheelVehicleTypes.WheelConfig }, {} :: typeof({ __index = Wheel })))
	& BaseObject.BaseObject

function Wheel.new(wheelObj: Model, wheelConfig: WheelVehicleTypes.WheelConfig): Wheel
	local self = setmetatable(BaseObject.new(wheelObj), Wheel)

	self._config = wheelConfig

	return self
end

function Wheel.UpdateStepped(self: Wheel, deltaTimeSim: number): Wheel
	debug.profilebegin("WheelVehicleWheelClient:UpdateStepped")

	print("ah")

	debug.profileend()
	return self
end

return Wheel
