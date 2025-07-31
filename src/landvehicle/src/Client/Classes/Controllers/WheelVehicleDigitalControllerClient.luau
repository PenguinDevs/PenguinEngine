--!strict

--[=[
    Control a wheel vehicle with digital inputs.

    @client
    @class WheelVehicleDigitalControllerClient
]=]

local require = require(script.Parent.loader).load(script)

local InputKeyMapListProvider = require("InputKeyMapListProvider")
local Maid = require("Maid")
local ServiceBag = require("ServiceBag")
local Spring = require("Spring")
local WheelVehicleSuspensionControllerClient = require("WheelVehicleSuspensionControllerClient")

local RunService = game:GetService("RunService")

local ContextActionService = game:GetService("ContextActionService")

local function assignSpringUpdate(
	spring: Spring.Spring<number>,
	maid: Maid.Maid,
	name: string,
	suspensionController: WheelVehicleSuspensionControllerClient.SuspensionController,
	fieldNameToAssign: string
)
	maid[name] = RunService.PostSimulation:Connect(function(deltaTimeSim)
		local position = spring.Position
		suspensionController[fieldNameToAssign] = position

		if math.abs(position - spring.Target) < 0.001 then
			suspensionController[fieldNameToAssign] = spring.Target
			maid[name] = nil

			return
		end
	end)
end

local WheelVehicleDigitalController = {}
WheelVehicleDigitalController.ClassName = "WheelVehicleDigitalController"
WheelVehicleDigitalController.__index = WheelVehicleDigitalController

export type WheelVehicleDigitalController = typeof(setmetatable(
	{} :: {
		_driverInputKeyMap: InputKeyMapListProvider.InputKeyMapListProvider,
		_serviceBag: ServiceBag.ServiceBag,
		_suspensionController: WheelVehicleSuspensionControllerClient.SuspensionController,
		_steeringSpring: Spring.Spring<number>,
		_accelerationSpring: Spring.Spring<number>,
		_brakeSpring: Spring.Spring<number>,
		_maid: Maid.Maid,
		_vehicleObj: Model,
		player: Player,
	},
	{} :: typeof({ __index = WheelVehicleDigitalController })
)) & Maid.Maid

function WheelVehicleDigitalController.new(
	vehicleObj: Model,
	_serviceBag: ServiceBag.ServiceBag,
	player: Player,
	suspensionController: WheelVehicleSuspensionControllerClient.SuspensionController
)
	local self = setmetatable({}, WheelVehicleDigitalController)

	self._maid = Maid.new()

	self._serviceBag = _serviceBag
	self._driverInputKeyMap = self._serviceBag:GetService(require("WheelVehicleDriverInputKeyMap"))
	self.player = player
	self._suspensionController = suspensionController
	self._vehicleObj = vehicleObj
	self._steeringSpring = Spring.new(0)
	self._accelerationSpring = Spring.new(0)
	self._brakeSpring = Spring.new(0)

	-- TODO: Spring damper and speed to be configurable.
	self._steeringSpring.Damper = 1
	self._steeringSpring.Speed = 11

	self._accelerationSpring.Damper = 1
	self._accelerationSpring.Speed = 11

	self._brakeSpring.Damper = 1
	self._brakeSpring.Speed = 11

	local steerLeftKeyMapList = self._driverInputKeyMap:GetInputKeyMapList("STEER_LEFT")
	self._maid:GiveTask(steerLeftKeyMapList:ObserveInputEnumsList():Subscribe(function(...)
		self._maid.contextAction = ContextActionService:BindAction(
			steerLeftKeyMapList:GetBindingName(),
			function(_, inputState, _)
				if inputState == Enum.UserInputState.Begin then
					self._steeringSpring.Target = -1
				elseif inputState == Enum.UserInputState.End then
					if self._steeringSpring.Target < 0 then
						self._steeringSpring.Target = 0
					end
				end

				assignSpringUpdate(
					self._steeringSpring,
					self._maid,
					"steering",
					self._suspensionController,
					"steeringAngleInput"
				)
			end,
			false,
			unpack(...)
		)
	end))

	local steerRightKeyMapList = self._driverInputKeyMap:GetInputKeyMapList("STEER_RIGHT")
	self._maid:GiveTask(steerRightKeyMapList:ObserveInputEnumsList():Subscribe(function(...)
		self._maid.contextAction = ContextActionService:BindAction(
			steerRightKeyMapList:GetBindingName(),
			function(_, inputState, _)
				if inputState == Enum.UserInputState.Begin then
					self._steeringSpring.Target = 1
				elseif inputState == Enum.UserInputState.End then
					if self._steeringSpring.Target > 0 then
						self._steeringSpring.Target = 0
					end
				end

				assignSpringUpdate(
					self._steeringSpring,
					self._maid,
					"steering",
					self._suspensionController,
					"steeringAngleInput"
				)
			end,
			false,
			unpack(...)
		)
	end))

	local accelerateKeyMapList = self._driverInputKeyMap:GetInputKeyMapList("ACCELERATE")
	self._maid:GiveTask(accelerateKeyMapList:ObserveInputEnumsList():Subscribe(function(...)
		self._maid.contextAction = ContextActionService:BindAction(
			accelerateKeyMapList:GetBindingName(),
			function(_, inputState, _)
				if inputState == Enum.UserInputState.Begin then
					self._accelerationSpring.Target = 1
				else
					self._accelerationSpring.Target = 0
				end

				assignSpringUpdate(
					self._accelerationSpring,
					self._maid,
					"acceleration",
					self._suspensionController,
					"accelerationInput"
				)
			end,
			false,
			unpack(...)
		)
	end))

	local brakeKeyMapList = self._driverInputKeyMap:GetInputKeyMapList("BRAKE")
	self._maid:GiveTask(brakeKeyMapList:ObserveInputEnumsList():Subscribe(function(...)
		self._maid.contextAction = ContextActionService:BindAction(
			brakeKeyMapList:GetBindingName(),
			function(_, inputState, _)
				if inputState == Enum.UserInputState.Begin then
					self._brakeSpring.Target = 1
				else
					self._brakeSpring.Target = 0
				end

				assignSpringUpdate(self._brakeSpring, self._maid, "brake", self._suspensionController, "brakeInput")
			end,
			false,
			unpack(...)
		)
	end))

	return self
end

function WheelVehicleDigitalController:Destroy()
	self._maid:DoCleaning()
end

return WheelVehicleDigitalController
