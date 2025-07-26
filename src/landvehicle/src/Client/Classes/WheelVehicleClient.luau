--[=[
	Base class for wheel-based vehicles such as sedans, meant to be used with binders.
    This class exports a [Binder].
	While a vehicle model is bound with this class, it is considered a vehicle.

	:::tip
	Initialise this whole system through [LandVehicleServiceClient].
	:::

	```lua
	-- Be sure to do the service init on the server too
	local ServiceBag = require("ServiceBag")
	local WheelVehicleClient = require("WheelVehicleClient")

	local serviceBag = ServiceBag.new()
	serviceBag:GetService(require("LandVehicleServiceClient"))

	serviceBag:Init()
	serviceBag:Start()

	-- Register the part as a vehicle
	WheelVehicleClient:Tag(part)

	-- Unregister the part as a vehicle
	WheelVehicleClient:Untag(part)
	```

    @client
	@class WheelVehicle
]=]

local require = require(script.Parent.loader).load(script)

local Binder = require("Binder")
local MacPhersonStrutSuspensionClient = require("MacPhersonStrutSuspensionClient")
local MultiLinkSuspensionClient = require("MultiLinkSuspensionClient")
local Rx = require("Rx")
local WheelVehicle = require("WheelVehicle")
local WheelVehicleConfigReader = require("WheelVehicleConfigReader")
local WheelVehicleConstants = require("WheelVehicleConstants")
local WheelVehicleSuspensionClient = require("WheelVehicleSuspensionClient")
local WheelVehicleTypes = require("WheelVehicleTypes")

local CollectionService = game:GetService("CollectionService")

SUSPENSION_MAPPING = {
	[WheelVehicleConstants.SUSPENSION_TYPES.MACPHERSON_STRUT] = MacPhersonStrutSuspensionClient,
	[WheelVehicleConstants.SUSPENSION_TYPES.MULTI_LINK] = MultiLinkSuspensionClient,
} :: { [WheelVehicleTypes.SuspensionTypes]: WheelVehicleSuspensionClient.SuspensionClient }

local WheelVehicleClient = setmetatable({}, WheelVehicle:GetConstructor())
WheelVehicleClient.ClassName = "WheelVehicleClient"
WheelVehicleClient.__index = WheelVehicleClient

export type WheelVehicleClient = typeof(setmetatable(
	{} :: {
		_suspensions: { [WheelVehicleTypes.Positions]: WheelVehicleSuspensionClient.SuspensionClient },
	},
	{} :: typeof({ __index = WheelVehicleClient })
)) & WheelVehicle.WheelVehicle

--[=[
	Constructs a new WheelVehicleClient. Should be done via [Binder] which is returned by [WheelVehicleClient].
	@param vehicle Model
	@return WheelVehicleClient
]=]
function WheelVehicleClient.new(vehicle: Model): WheelVehicleClient
	local localCopy, reverseLocalCopy = WheelVehicleClient._useLocalCopy(vehicle)
	local self = setmetatable(WheelVehicle:GetConstructor().new(localCopy), WheelVehicleClient) :: WheelVehicleClient
	self._maid:Add(reverseLocalCopy)

	self._serverCopyVehicle = vehicle

	Rx.fromSignal(self._serverCopyVehicle:GetPropertyChangedSignal("Parent")):Subscribe(function(parent)
		if not parent then
			self._obj:Destroy()
		end
	end)

	self._config = WheelVehicleConfigReader:Read(self._obj)

	self._suspensions = {}
	self:_createSuspensions()

	self:ListenToModelChanges()

	for _, suspension in pairs(self._suspensions) do
		suspension:Start()
	end
	-- self._vehicle.PrimaryPart.Anchored = false

	self:ShowDebugAnnotations()

	return self
end

--[=[
	Create a local copy of this vehicle whose physics is unaffected by the server's authority in replication.
	@return Model
]=]
function WheelVehicleClient._useLocalCopy(serverCopy: Model): (Model, () -> ())
	assert(serverCopy:IsA("Model"), "Expected vehicle to be a Model")
	assert(serverCopy.PrimaryPart, "Expected vehicle to have a PrimaryPart")

	local localCopy = Instance.fromExisting(serverCopy)
	CollectionService:RemoveTag(localCopy, "WheelVehicle")
	localCopy.Name = `{serverCopy.Name} (Local Copy)`

	local primaryPart = Instance.fromExisting(serverCopy.PrimaryPart)
	primaryPart.Parent = localCopy
	localCopy.PrimaryPart = primaryPart

	local modelLevelChildren = {}
	for _, obj in pairs(serverCopy:GetChildren()) do
		if obj ~= serverCopy.PrimaryPart then
			obj.Parent = localCopy
			table.insert(modelLevelChildren, obj)
		end
	end

	local primaryPartLevelChildren = {}
	for _, obj in pairs(serverCopy.PrimaryPart:GetChildren()) do
		obj.Parent = localCopy.PrimaryPart
		table.insert(primaryPartLevelChildren, obj)
	end

	localCopy.Parent = game.Workspace

	local function reverseLocalCopy()
		for _, child in pairs(modelLevelChildren) do
			child.Parent = serverCopy
		end

		for _, child in pairs(primaryPartLevelChildren) do
			child.Parent = serverCopy.PrimaryPart
		end
	end

	return localCopy, reverseLocalCopy
end

function WheelVehicleClient:_createSuspensions()
	self = self :: WheelVehicleClient -- Using the usual way to get the self type hinting breaks the VSCode Luau language server linting.

	for _, suspension in pairs(self._config.suspensions) do
		local suspensionClass = SUSPENSION_MAPPING[suspension.suspension.type]
		if not suspensionClass then
			error("Unsupported suspension type: " .. tostring(suspension.suspension.type))
		end

		self._suspensions[suspension.position] = suspensionClass.new(self._obj, suspension)
	end
end
return Binder.new("WheelVehicle", WheelVehicleClient)
