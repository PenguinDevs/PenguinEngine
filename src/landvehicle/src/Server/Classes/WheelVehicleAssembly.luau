--[=[
	Handles the assembly of wheel-based vehicles, creating suspension links and wheels.
	This module contains all the logic for physically assembling a vehicle from configuration.

	@class WheelVehicleAssembly
]=]

local require = require(script.Parent.loader).load(script)

local CFrameUtils = require("CFrameUtils")
local WheelVehicleTypes = require("WheelVehicleTypes")

local WheelVehicleAssembly = {}
WheelVehicleAssembly.ClassName = "WheelVehicleAssembly"

--[=[
	Assembles a vehicle by creating suspension links and wheels based on the configuration.
	@param vehicle Model -- The model of the vehicle. Must have a PrimaryPart set.
	@param wheelVehicleConfig WheelVehicleTypes.WheelVehicleConfig -- The vehicle configuration
]=]
function WheelVehicleAssembly.assemble(vehicle: Model, wheelVehicleConfig: WheelVehicleTypes.WheelVehicleConfig)
	assert(vehicle.PrimaryPart, "Vehicle must have a PrimaryPart set for assembly.")
	assert(vehicle.PrimaryPart:IsA("BasePart"), "PrimaryPart must be a BasePart.")

	local suffixesUsed = {}

	local springsFolder = Instance.new("Folder")
	springsFolder.Name = "Springs"
	springsFolder.Parent = vehicle

	local suspensions = wheelVehicleConfig.suspensions
	for i, suspensionConfig in ipairs(suspensions) do
		local suffix = "F"
		if suspensionConfig.topLinkCFrameRelative.Position.Z > 0 then
			suffix = "R"
		end

		local offset = CFrame.Angles(0, 0, 0)
		if suspensionConfig.topLinkCFrameRelative.Position.X < 0 then
			suffix = suffix .. "L"
			offset = offset * CFrame.Angles(0, math.pi, 0) -- Flip orientation for right side
		else
			suffix = suffix .. "R"
		end

		-- Count occurrences and add suffix if needed
		suffixesUsed[suffix] = (suffixesUsed[suffix] or 0) + 1
		if suffixesUsed[suffix] > 1 then
			suffix = suffix .. tostring(suffixesUsed[suffix])
		end

		WheelVehicleAssembly._createAttachment(vehicle.PrimaryPart, suspensionConfig, springsFolder, offset, suffix)
	end
end

--[=[
	Creates a suspension system with top, mid, and bottom links, and optionally a wheel.
	@param parent BasePart -- The parent part to attach the suspension to
	@param suspensionConfig WheelVehicleTypes.SuspensionConfig -- The suspension configuration
	@param offset CFrame -- Orientation offset for the suspension
	@param suffix string -- Suffix for naming the suspension components
]=]
function WheelVehicleAssembly._createAttachment(
	parent: BasePart,
	suspensionConfig: WheelVehicleTypes.SuspensionConfig,
	springsFolder: Folder,
	offset: CFrame,
	suffix: string
)
	-- Create the suspension links and wheel based on the configuration
	local topLink =
		WheelVehicleAssembly._createLink(parent, suspensionConfig.topLinkCFrameRelative * offset, "Top", suffix)
	local midLink = WheelVehicleAssembly._createLink(topLink, suspensionConfig.midLinkCFrameRelative, "Mid", suffix)
	local bottomLink =
		WheelVehicleAssembly._createLink(midLink, suspensionConfig.bottomLinkCFrameRelative, "Bottom", suffix)

	local springConstraint = Instance.new("SpringConstraint")
	springConstraint.Name = "Spring" .. suffix
	springConstraint.Attachment0 = topLink
	springConstraint.Attachment1 = midLink
	springConstraint.Visible = true
	springConstraint.Radius = 0.2
	springConstraint.Parent = springsFolder

	if suspensionConfig.wheel then
		WheelVehicleAssembly._createWheel(bottomLink, suspensionConfig.wheel, suffix)
	end
end

--[=[
	Creates a suspension link (attachment) relative to the parent part.
	@param parent BasePart -- The parent part to attach the link to
	@param CFrameRelative CFrame -- The relative CFrame for the link
	@param prefix string -- Prefix for naming the link
	@param suffix string -- Suffix for naming the link
	@return Attachment -- The created attachment
]=]
function WheelVehicleAssembly._createLink(
	parent: BasePart,
	CFrameRelative: CFrame,
	prefix: string,
	suffix: string
): Attachment
	-- Create a link part relative to the parent part
	local link = Instance.new("Attachment")
	link.Name = prefix .. "Link" .. suffix
	link.CFrame = CFrameRelative
	link.Visible = true
	link.Parent = parent

	return link
end

--[=[
	Creates a wheel part with proper constraints relative to the parent attachment.
	@param parent Attachment -- The parent attachment to attach the wheel to
	@param wheelConfig WheelVehicleTypes.WheelConfig -- The wheel configuration
	@param suffix string -- Suffix for naming the wheel
	@return Part -- The created wheel part
]=]
function WheelVehicleAssembly._createWheel(
	parent: Attachment,
	wheelConfig: WheelVehicleTypes.WheelConfig,
	suffix: string
): Part
	-- Create a wheel part relative to the parent part
	local wheel = Instance.new("Part")
	wheel.Name = "Wheel" .. suffix
	wheel.CastShadow = false
	wheel.Transparency = 0.5
	wheel.Size = Vector3.new(wheelConfig.span, wheelConfig.radius * 2, wheelConfig.radius * 2)
	-- CFrame is overriden by its attachment for the RigidConstraint
	-- wheel.CFrame = parent.WorldCFrame * wheelConfig.CFrameRelative
	wheel.Shape = Enum.PartType.Cylinder
	wheel.TopSurface = Enum.SurfaceType.Smooth
	wheel.BottomSurface = Enum.SurfaceType.Smooth
	wheel.LeftSurface = Enum.SurfaceType.Hinge

	local rigidAttachment = Instance.new("Attachment")
	rigidAttachment.Name = "RigidAttachment"
	rigidAttachment.Parent = wheel
	rigidAttachment.CFrame = CFrameUtils.mirror(wheelConfig.CFrameRelative, Vector3.new(0, 0, 0), Vector3.new(-1, 0, 0))
		* CFrame.Angles(0, math.rad(180), 0)

	local rigidConstraint = Instance.new("RigidConstraint")
	rigidConstraint.Name = "RigidConstraint"
	rigidConstraint.Attachment0 = parent
	rigidConstraint.Attachment1 = rigidAttachment
	rigidConstraint.Parent = wheel

	wheel.Parent = parent

	return wheel
end

return WheelVehicleAssembly
