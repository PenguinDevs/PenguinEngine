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
local Brio = require("Brio")
local MacPhersonStrutSuspensionClient = require("MacPhersonStrutSuspensionClient")
local Maid = require("Maid")
local MultiLinkSuspensionClient = require("MultiLinkSuspensionClient")
local Rx = require("Rx")
local RxBrioUtils = require("RxBrioUtils")
local RxInstanceUtils = require("RxInstanceUtils")
local WheelVehicle = require("WheelVehicle")
local WheelVehicleAttributes = require("WheelVehicleAttributes")
local WheelVehicleConfigReader = require("WheelVehicleConfigReader")
local WheelVehicleConstants = require("WheelVehicleConstants")
local WheelVehicleSuspensionClient = require("WheelVehicleSuspensionClient")
local WheelVehicleSuspensionControllerClient = require("WheelVehicleSuspensionControllerClient")
local WheelVehicleTypes = require("WheelVehicleTypes")
local WheelVehicleUtils = require("WheelVehicleUtils")
local WheelVehicleWheelClient = require("WheelVehicleWheelClient")

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local wheelCacheFolder = Instance.new("Folder")
wheelCacheFolder.Name = "WheelVehicleWheelsCache"
wheelCacheFolder.Parent = ReplicatedStorage

SUSPENSION_MAPPING = {
	[WheelVehicleConstants.SUSPENSION_TYPES.MACPHERSON_STRUT] = MacPhersonStrutSuspensionClient,
	[WheelVehicleConstants.SUSPENSION_TYPES.MULTI_LINK] = MultiLinkSuspensionClient,
} :: { [WheelVehicleTypes.SuspensionTypes]: WheelVehicleSuspensionClient.Suspension }

local WheelVehicleClient = setmetatable({}, WheelVehicle:GetConstructor())
WheelVehicleClient.ClassName = "WheelVehicleClient"
WheelVehicleClient.__index = WheelVehicleClient

export type WheelVehicleClient = typeof(setmetatable(
	{} :: {
		_config: WheelVehicleTypes.WheelVehicleConfig,
		_serverCopyVehicle: Model,
		_suspensions: { [WheelVehicleTypes.Positions]: WheelVehicleSuspensionClient.Suspension },
		_suspensionController: WheelVehicleSuspensionControllerClient.SuspensionController,
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

	self:_createMass()

	self._suspensions = {}
	self:_createSuspensions()
	self._suspensionController = WheelVehicleSuspensionControllerClient.new(self._obj, self._suspensions)
	self._suspensionController:Start()

	self:ListenToModelChanges()

	self:StoreDebugAnnotations()
	self:ShowDebugAnnotations()

	task.spawn(function()
		workspace:WaitForChild("Baseplate")
		self._obj.PrimaryPart.Anchored = false

		-- NOTE: Lesson learnt: don't assume you can use a 1x1x1 cube as the center of mass as the only base part with mass.
		-- local attachment0 = Instance.new("Attachment")
		-- attachment0.Orientation = Vector3.new(0, 0, 90)
		-- attachment0.Parent = self._obj.PrimaryPart

		-- local anchoredPart = Instance.new("Part")
		-- anchoredPart.Anchored = true
		-- anchoredPart.CanCollide = false
		-- anchoredPart.Parent = workspace

		-- local attachment1 = Instance.new("Attachment")
		-- attachment1.Orientation = Vector3.new(0, 0, 90)
		-- attachment1.Parent = anchoredPart

		-- local prismaticConstraint = Instance.new("PrismaticConstraint")
		-- prismaticConstraint.Parent = attachment0
		-- prismaticConstraint.Attachment0 = attachment0
		-- prismaticConstraint.Attachment1 = attachment1

		-- while true do
		-- 	task.wait(1)
		-- 	prismaticConstraint.Enabled = not prismaticConstraint.Enabled
		-- end
	end)

	return self
end

--[=[
	Create a local copy of this vehicle whose physics is unaffected by the server's authority in replication.
	@return Model
]=]
function WheelVehicleClient._useLocalCopy(serverCopy: Model): (Model, Maid.Maid)
	assert(serverCopy:IsA("Model"), "Expected vehicle to be a Model")
	assert(serverCopy.PrimaryPart, "Expected vehicle to have a PrimaryPart")

	local maid = Maid.new()

	-- localCopy will be cleaned up by the BaseObject's maid anyways.
	local localCopy = Instance.fromExisting(serverCopy)
	CollectionService:RemoveTag(localCopy, "WheelVehicle")
	localCopy.Name = `{serverCopy.Name} (Local Copy)`
	localCopy.Parent = workspace

	local primaryPart = Instance.fromExisting(serverCopy.PrimaryPart)
	primaryPart.Parent = localCopy
	localCopy.PrimaryPart = primaryPart

	local localCopyWheelsFolder = Instance.new("Folder")
	localCopyWheelsFolder.Name = WheelVehicleConstants.FOLDERS.WHEELS
	localCopyWheelsFolder.Parent = localCopy

	local serverCopyWheelsFolder = serverCopy:WaitForChild(WheelVehicleConstants.FOLDERS.WHEELS)
	serverCopyWheelsFolder.Parent = wheelCacheFolder
	maid[serverCopyWheelsFolder] = function()
		serverCopyWheelsFolder.Parent = serverCopy
	end

	for _, wheel in pairs(serverCopyWheelsFolder:GetChildren()) do
		if wheel:IsA("BasePart") then
			local wheelCopy = Instance.fromExisting(wheel)
			wheelCopy.Parent = localCopyWheelsFolder

			for _, obj in pairs(wheel:GetChildren()) do
				obj.Parent = wheelCopy
				maid[obj] = function()
					obj.Parent = wheel
				end
			end
		end
	end

	for _, obj in pairs(serverCopy:GetChildren()) do
		if obj ~= serverCopy.PrimaryPart and obj ~= serverCopyWheelsFolder then
			obj.Parent = localCopy
			maid[obj] = function()
				obj.Parent = serverCopy
			end
		end
	end

	for _, obj in pairs(serverCopy.PrimaryPart:GetChildren()) do
		obj.Parent = localCopy.PrimaryPart
		maid[obj] = function()
			obj.Parent = serverCopy.PrimaryPart
		end
	end

	return localCopy, maid
end

function WheelVehicleClient._createMass(self: WheelVehicleClient)
	-- Create a mass part to be used as the center of mass.
	local massPart = Instance.new("Part")
	massPart.Name = "MassPart"
	massPart.Transparency = 1
	massPart.Size = self._config.chassis.massSize
	massPart.CanCollide = false
	massPart.Anchored = false
	massPart.CustomPhysicalProperties = PhysicalProperties.new(
		self._config.chassis.mass / (massPart.Size.X * massPart.Size.Y * massPart.Size.Z),
		0.3, -- Friction
		0.5, -- Elasticity
		1, -- FrictionWeight
		1 -- ElasticityWeight
	)
	massPart.Parent = self._obj
	self._maid.massPart = massPart

	local weld = Instance.new("Weld")
	weld.Name = "MassPartWeld"
	weld.Part0 = self._obj.PrimaryPart
	weld.Part1 = massPart
	weld.Parent = self._obj.PrimaryPart

	weld.C0 = CFrame.new(self._config.chassis.massOffset)

	return massPart
end

function WheelVehicleClient:_createSuspensions()
	self = self :: WheelVehicleClient -- Using the usual way to get the self type hinting breaks the VSCode Luau language server linting.

	for _, suspension in pairs(self._config.suspensions) do
		local suspensionClass = SUSPENSION_MAPPING[suspension.suspension.type]
		if not suspensionClass then
			error("Unsupported suspension type: " .. tostring(suspension.suspension.type))
		end

		local suspensionInstance = suspensionClass.new(self._obj, suspension)
		self._suspensions[suspension.position] = suspensionInstance
		suspensionInstance._maid:GiveTask(function()
			self._suspensions[suspension.position] = nil
		end)
		self._maid[suspension.position] = suspensionInstance

		local wheelObj = self._obj[WheelVehicleConstants.FOLDERS.WHEELS]:FindFirstChild(`Wheel{suspension.position}`)
		if suspensionInstance._config.wheel and wheelObj then
			local wheelInstance = WheelVehicleWheelClient.new(
				wheelObj,
				suspensionInstance._config.wheel,
				WheelVehicleUtils:GetLinks(self._obj, suspension.position),
				suspensionInstance.forceAttachment
			)
			suspensionInstance.wheel = wheelInstance
			wheelInstance._maid:GiveTask(function()
				suspensionInstance.wheel = nil
			end)
			suspensionInstance._maid:GiveTask(wheelInstance)
		end
	end
end

function WheelVehicleClient:_applyModel(model: Model): Model
	self = self :: WheelVehicleClient -- Using the usual way to get the self type hinting breaks the VSCode Luau language server linting.

	model = WheelVehicle:GetConstructor()._applyModel(self, model)

	self._maid:GiveTask(RxInstanceUtils.observeLastNamedChildBrio(model, "Folder", WheelVehicleConstants.FOLDERS.WHEELS)
		:Pipe({
			RxBrioUtils.switchMapBrio(function(container: Instance)
				return RxInstanceUtils.observeChildrenOfClassBrio(container, "Model")
			end),
		})
		:Subscribe(function(brio: Brio.Brio<Model>)
			local maid, obj = brio:ToMaidAndValue()

			local position = obj:GetAttribute(WheelVehicleAttributes.POSITION) :: WheelVehicleTypes.Positions

			local suspension = self._suspensions[position]

			if suspension then
				if suspension.wheel then
					suspension.wheel:ApplyModel(obj)
					suspension._maid.wheelModel = obj
					maid:GiveTask(function()
						suspension._maid.wheelModel = nil
					end)
				else
					warn(`WheelVehicleClient: _applyModel: No wheel found for suspension at position {position}.`)
				end
			else
				warn(`WheelVehicleClient: _applyModel: No suspension found for wheel at position {position}.`)
				obj:Destroy()
			end
		end))

	return model
end

return Binder.new("WheelVehicle", WheelVehicleClient)
