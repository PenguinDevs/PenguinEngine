--[=[
    Manage seats in a wheel vehicle.

    @client
    @class WheeelVehicleSeatClient
]=]

local require = require(script.Parent.loader).load(script)

local AttributeValue = require("AttributeValue")
local BaseObject = require("BaseObject")
local WheelVehicleAttributes = require("WheelVehicleAttributes")
local WheelVehicleConstants = require("WheelVehicleConstants")
local WheelVehicleTypes = require("WheelVehicleTypes")

local PROXIMITY_PROMPT_HOLD_DURATION = 0.5
-- NOTE: Subject to change once keybindable settings are implemented.
local PROXIMITY_PROMPT_KEYBOARD_KEY_CODE = Enum.KeyCode.F
local PROXIMITY_PROMPT_GAMEPAD_KEY_CODE = Enum.KeyCode.ButtonB

local Seat = setmetatable({}, BaseObject)
Seat.ClassName = "Seat"
Seat.__index = Seat

export type Seat =
	typeof(setmetatable(
		{} :: { _seatTypeAttribute: AttributeValue.AttributeValue<WheelVehicleTypes.SeatTypes> },
		{} :: typeof({ __index = Seat })
	))
	& BaseObject.BaseObject

function Seat.new(vehicleObj: Model, seat: Seat | VehicleSeat): Seat
	assert(vehicleObj:IsA("Model"), "Bad vehicleObj")
	assert(vehicleObj.PrimaryPart, "Vehicle must have a PrimaryPart set")
	assert(seat:IsA("Seat") or seat:IsA("VehicleSeat"), "Bad seat")

	local seatAttachment = Instance.new("Attachment")
	seatAttachment.Name = "SeatAttachment"
	seatAttachment.Parent = vehicleObj.PrimaryPart

	local self = setmetatable(BaseObject.new(seatAttachment), Seat) :: Seat

	self._seatTypeAttribute =
		AttributeValue.new(seatAttachment, WheelVehicleAttributes.SEAT_TYPE, WheelVehicleConstants.SEAT_TYPES.PASSENGER)

	if seat:IsA("VehicleSeat") then
		self._seatTypeAttribute.Value = WheelVehicleConstants.SEAT_TYPES.DRIVER
	end

	-- Use ; to deal with the () ambiguity for the Luau language server.
	seatAttachment.WorldCFrame = seat.CFrame; -- Luau language server sucks at | types, so just define it as a Seat.
	(seat :: Seat):Destroy()

	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.HoldDuration = PROXIMITY_PROMPT_HOLD_DURATION
	proximityPrompt.KeyboardKeyCode = PROXIMITY_PROMPT_KEYBOARD_KEY_CODE
	proximityPrompt.GamepadKeyCode = PROXIMITY_PROMPT_GAMEPAD_KEY_CODE
	proximityPrompt.ObjectText = vehicleObj.Name
	proximityPrompt.RequiresLineOfSight = false
	proximityPrompt.Parent = seatAttachment

	self._seatTypeAttribute:Observe():Subscribe(function(seatType: WheelVehicleTypes.SeatTypes)
		if seatType == WheelVehicleConstants.SEAT_TYPES.DRIVER then
			proximityPrompt.ActionText = "Drive"
		elseif seatType == WheelVehicleConstants.SEAT_TYPES.PASSENGER then
			proximityPrompt.ActionText = "Sit"
		end
	end)

	return self
end

return Seat
