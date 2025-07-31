--[=[
    Manage passenger sitting in a wheel vehicle.

    @client
    @class WheeelVehiclePassengerClient
]=]

local require = require(script.Parent.loader).load(script)

local Maid = require("Maid")
local ServiceBag = require("ServiceBag")
local ContextActionService = game:GetService("ContextActionService")
local InputKeyMapListProvider = require("InputKeyMapListProvider")

local Passenger = {}
Passenger.ClassName = "Passenger"
Passenger.__index = Passenger

export type Passenger = typeof(setmetatable(
	{} :: {
		_serviceBag: ServiceBag.ServiceBag,
		_maid: Maid.Maid,
		_seatInputKeyMap: InputKeyMapListProvider.InputKeyMapListProvider,
		_vehicleObj: Model,
		player: Player,
	},
	{} :: typeof({ __index = Passenger })
))

function Passenger.new(vehicleObj: Model, _serviceBag: ServiceBag.ServiceBag, player: Player): Passenger
	local self = setmetatable({}, Passenger)

	self._serviceBag = _serviceBag
	self._maid = Maid.new()
	self._vehicleObj = vehicleObj
	self._seatInputKeyMap = self._serviceBag:GetService(require("WheelVehicleSeatInputKeyMap"))

	local exitKeyMapList = self._seatInputKeyMap:GetInputKeyMapList("EXIT")

	self._maid:GiveTask(exitKeyMapList:ObserveInputEnumsList():Subscribe(function(...)
		self._maid.contextAction = ContextActionService:BindAction(
			exitKeyMapList:GetBindingName(),
			function(_, inputState, _)
				print("ah")
				if inputState ~= Enum.UserInputState.Begin then
					return
				end
				self:Destroy()
			end,
			false,
			unpack(...)
		)
	end))

	self.player = player

	return self
end

function Passenger:Destroy()
	self._maid:DoCleaning()
end

return Passenger
