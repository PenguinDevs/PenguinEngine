--[=[
    Manage seats in a wheel vehicle.

    @client
    @class WheeelVehicleSeatClient
]=]

local require = require(script.Parent.loader).load(script)

local AttributeValue = require("AttributeValue")
local BaseObject = require("BaseObject")
local Brio = require("Brio")
local Maid = require("Maid")
local Rx = require("Rx")
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

export type Seat = typeof(setmetatable(
	{} :: {
		_seatTypeAttribute: AttributeValue.AttributeValue<WheelVehicleTypes.SeatTypes>,
		_vehicleObj: Model,
		proximityPrompt: ProximityPrompt,
	},
	{} :: typeof({ __index = Seat })
)) & BaseObject.BaseObject

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

	self._vehicleObj = vehicleObj

	if seat:IsA("VehicleSeat") then
		self._seatTypeAttribute.Value = WheelVehicleConstants.SEAT_TYPES.DRIVER
	end

	-- Use ; to deal with the () ambiguity for the Luau language server.
	seatAttachment.WorldCFrame = seat.CFrame; -- Luau language server sucks at | types, so just define it as a Seat.
	(seat :: Seat):Destroy()

	self:_createProximityPrompt()

	return self
end

function Seat._createProximityPrompt(self: Seat)
	self.proximityPrompt = Instance.new("ProximityPrompt")
	self.proximityPrompt.HoldDuration = PROXIMITY_PROMPT_HOLD_DURATION
	self.proximityPrompt.KeyboardKeyCode = PROXIMITY_PROMPT_KEYBOARD_KEY_CODE
	self.proximityPrompt.GamepadKeyCode = PROXIMITY_PROMPT_GAMEPAD_KEY_CODE
	self.proximityPrompt.ObjectText = self._vehicleObj.Name
	self.proximityPrompt.RequiresLineOfSight = false
	self.proximityPrompt.Parent = self._obj

	local brio = Brio.new(self.proximityPrompt)
	local maid = brio:ToMaid()
	Rx.fromSignal(self.proximityPrompt:GetPropertyChangedSignal("Parent")):Subscribe(function(parent)
		if not parent then
			brio:Destroy()
		end
	end)

	maid:GiveTask(self._seatTypeAttribute:Observe():Subscribe(function(seatType: any)
		-- Explicitly cast seatType to the expected literal type
		local castedSeatType = seatType :: WheelVehicleTypes.SeatTypes
		if castedSeatType == WheelVehicleConstants.SEAT_TYPES.DRIVER then
			self.proximityPrompt.ActionText = "Drive"
		elseif castedSeatType == WheelVehicleConstants.SEAT_TYPES.PASSENGER then
			self.proximityPrompt.ActionText = "Sit"
		end
	end))

	self.proximityPrompt.Triggered:Connect(function(player: Player)
		local maid = Maid.new()

		if not player.Character then
			return
		end

		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if not player.Character.PrimaryPart or not humanoid then
			return
		end

		local playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
		playerModule:GetControls():Disable()

		player.Character:PivotTo(
			self._obj.WorldCFrame * CFrame.new(0, player.Character.PrimaryPart.Size.Y / 2 - 0.5, 0)
		)

		local weld = Instance.new("WeldConstraint")
		weld.Name = "SeatWeld"
		weld.Part0 = self._vehicleObj.PrimaryPart
		weld.Part1 = player.Character.PrimaryPart
		weld.Parent = self._obj
		maid:GiveTask(weld)

		humanoid.PlatformStand = true
		task.spawn(function()
			task.wait(0.5)
			humanoid.Sit = true
		end)

		maid:GiveTask(function()
			humanoid.PlatformStand = false
			humanoid.Sit = false

			player.Character:PivotTo(self._obj * CFrame.new(0, 5, 0))

			playerModule:GetControls():Enable()
		end)
	end)
end

return Seat
