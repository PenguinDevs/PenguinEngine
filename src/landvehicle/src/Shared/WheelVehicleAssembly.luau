--[=[
	Handles the assembly of wheel-based vehicles, creating suspension links and wheels.
	This module contains all the logic for physically assembling a vehicle from configuration.

	@class WheelVehicleAssembly
]=]

local require = require(script.Parent.loader).load(script)

local DebugAnnotation = require("DebugAnnotation")
local WheelVehicleAttributes = require("WheelVehicleAttributes")
local WheelVehicleConstants = require("WheelVehicleConstants")
local WheelVehicleTypes = require("WheelVehicleTypes")

local WheelVehicleAssembly = {}
WheelVehicleAssembly.ClassName = "WheelVehicleAssembly"

--[=[
	Applies the customisation to the vehicle configuration.
	@param model Model -- The model of the vehicle. Must have a PrimaryPart set.
	@param config WheelVehicleTypes.WheelVehicleConfig -- The vehicle configuration
	@param customisation WheelVehicleTypes.WheelVehicleCustomisation -- The vehicle customisation
]=]
function WheelVehicleAssembly:ApplyCustomisation(
	model: Model,
	config: WheelVehicleTypes.WheelVehicleConfig,
	customisation: WheelVehicleTypes.WheelVehicleCustomisation
)
	local function categoriseSuspensions(suspensions: { WheelVehicleTypes.SuspensionConfig })
		local suspensionMap = {
			frontLeft = nil :: WheelVehicleTypes.SuspensionConfig?,
			frontRight = nil :: WheelVehicleTypes.SuspensionConfig?,
			rearLeft = nil :: WheelVehicleTypes.SuspensionConfig?,
			rearRight = nil :: WheelVehicleTypes.SuspensionConfig?,
		}

		for _, suspension in ipairs(suspensions) do
			local isFront = suspension.topLinkCFrameRelative.Position.Z < 0
			local isLeft = suspension.topLinkCFrameRelative.Position.X < 0

			if isFront and isLeft then
				suspensionMap.frontLeft = suspension
			elseif isFront and not isLeft then
				suspensionMap.frontRight = suspension
			elseif not isFront and isLeft then
				suspensionMap.rearLeft = suspension
			else
				suspensionMap.rearRight = suspension
			end
		end

		return suspensionMap
	end

	local function calculateToeInAngle(suspension: WheelVehicleTypes.SuspensionConfig?, toeIn: number): number
		if suspension and suspension.wheel then
			return -math.asin(toeIn / (suspension.wheel.radius * 2))
		end
		return 0
	end

	local function applySuspensionCustomisation(
		suspension: WheelVehicleTypes.SuspensionConfig,
		caster: number,
		toeAngle: number,
		camber: number,
		isLeft: boolean
	)
		local pivotFrom = suspension.topLinkCFrameRelative
			* suspension.midLinkCFrameRelative
			* suspension.bottomLinkCFrameRelative
			* suspension.wheelCFrameRelative.Position

		local toeSign = isLeft and 1 or -1
		local camberSign = isLeft and 1 or -1

		suspension.topLinkCFrameRelative = CFrame.new(pivotFrom)
			* CFrame.Angles(math.rad(caster), toeSign * toeAngle, camberSign * math.rad(camber))
			* suspension.topLinkCFrameRelative.Rotation

		local newPivotFrom = suspension.topLinkCFrameRelative
			* suspension.midLinkCFrameRelative
			* suspension.bottomLinkCFrameRelative
			* suspension.wheelCFrameRelative.Position

		suspension.topLinkCFrameRelative = suspension.topLinkCFrameRelative - (newPivotFrom - pivotFrom)
	end

	local suspensions = categoriseSuspensions(config.suspensions)

	local frontToeInAngle = calculateToeInAngle(suspensions.frontRight, customisation.suspensions.Front.toeIn)
	local rearToeInAngle = calculateToeInAngle(suspensions.rearRight, customisation.suspensions.Rear.toeIn)

	local suspensionConfigs = {
		{ suspensions.frontRight, customisation.suspensions.Front, frontToeInAngle, false },
		{ suspensions.frontLeft, customisation.suspensions.Front, frontToeInAngle, true },
		{ suspensions.rearRight, customisation.suspensions.Rear, rearToeInAngle, false },
		{ suspensions.rearLeft, customisation.suspensions.Rear, rearToeInAngle, true },
	}

	for _, config in ipairs(suspensionConfigs) do
		local suspension, customConfig, toeAngle, isLeft = config[1], config[2], config[3], config[4]
		if suspension then
			applySuspensionCustomisation(suspension, customConfig.caster, toeAngle, customConfig.camber, isLeft)
		end
	end
end

--[=[
	Assembles a vehicle by creating suspension links and wheels based on the configuration.
	@param vehicle Model -- The model of the vehicle. Must have a PrimaryPart set.
	@param wheelVehicleConfig WheelVehicleTypes.WheelVehicleConfig -- The vehicle configuration
	@param debugAnnotations WheelVehicleTypes.WheelVehicleAnnotations? -- Optional debug annotations for the vehicle
	@return Model -- The assembled vehicle model with suspension and wheels
]=]
function WheelVehicleAssembly:Assemble(
	vehicle: Model,
	model: Model,
	debugAnnotations: {},
	wheelVehicleConfig: WheelVehicleTypes.WheelVehicleConfig,
	debugAnnotationsConfig: WheelVehicleTypes.WheelVehicleAnnotations?
): Model
	assert(vehicle.PrimaryPart, "Vehicle must have a PrimaryPart set for assembly.")
	assert(vehicle.PrimaryPart:IsA("BasePart"), "PrimaryPart must be a BasePart.")

	local suffixesUsed = {}

	local springsFolder = Instance.new("Folder")
	springsFolder.Name = WheelVehicleConstants.FOLDERS.SPRINGS
	springsFolder.Parent = vehicle

	local wheelsFolder = Instance.new("Folder")
	wheelsFolder.Name = WheelVehicleConstants.FOLDERS.WHEELS
	wheelsFolder.Parent = vehicle

	local suspensions = wheelVehicleConfig.suspensions
	for i, suspensionConfig in ipairs(suspensions) do
		local suffix = "F"
		if suspensionConfig.topLinkCFrameRelative.Position.Z > 0 then
			suffix = "R"
		end

		local offset = CFrame.Angles(0, 0, 0)
		if suspensionConfig.topLinkCFrameRelative.Position.X < 0 then
			suffix = suffix .. "L"
			-- offset = offset * CFrame.Angles(0, math.pi, 0) -- Flip orientation for right side
		else
			suffix = suffix .. "R"
		end

		-- Count occurrences and add suffix if needed
		suffixesUsed[suffix] = (suffixesUsed[suffix] or 0) + 1
		if suffixesUsed[suffix] > 1 then
			suffix = suffix .. tostring(suffixesUsed[suffix])
		end

		WheelVehicleAssembly:_createSuspensionPoints(
			vehicle.PrimaryPart,
			suspensionConfig,
			springsFolder,
			wheelsFolder,
			offset,
			suffix,
			debugAnnotations,
			debugAnnotationsConfig
		)
	end

	vehicle:SetAttribute(WheelVehicleAttributes.MASS, wheelVehicleConfig.chassis.mass)
	vehicle:SetAttribute(WheelVehicleAttributes.MASS_SIZE, wheelVehicleConfig.chassis.massSize)

	return vehicle
end

--[=[
	Creates suspension points (attachments) with top, mid, and bottom links, and optionally a wheel.
	@param parent BasePart -- The parent part to attach the suspension to
	@param suspensionConfig WheelVehicleTypes.SuspensionConfig -- The suspension configuration
	@param offset CFrame -- Orientation offset for the suspension
	@param suffix string -- Suffix for naming the suspension components
]=]
function WheelVehicleAssembly:_createSuspensionPoints(
	parent: BasePart,
	suspensionConfig: WheelVehicleTypes.SuspensionConfig,
	springsFolder: Folder,
	wheelsFolder: Folder,
	offset: CFrame,
	suffix: string,
	debugAnnotations: {},
	debugAnnotationsConfig: WheelVehicleTypes.WheelVehicleAnnotations?
)
	local wheelAttachmentGlobalCFrame = suspensionConfig.topLinkCFrameRelative
		* offset
		* suspensionConfig.midLinkCFrameRelative
		* suspensionConfig.bottomLinkCFrameRelative
		* suspensionConfig.wheelCFrameRelative
	local x, _, _ = wheelAttachmentGlobalCFrame:ToEulerAnglesXYZ()

	-- Create the suspension links and wheel based on the configuration
	local topLink =
		WheelVehicleAssembly:_createAttachment(parent, suspensionConfig.topLinkCFrameRelative * offset, "Top", suffix)
	local midLink =
		WheelVehicleAssembly:_createAttachment(topLink, suspensionConfig.midLinkCFrameRelative, "Mid", suffix)
	local bottomLink =
		WheelVehicleAssembly:_createAttachment(midLink, suspensionConfig.bottomLinkCFrameRelative, "Bottom", suffix)
	local wheelLink = WheelVehicleAssembly:_createAttachment(
		bottomLink,
		suspensionConfig.wheelCFrameRelative * CFrame.Angles(x, 0, 0):Inverse(),
		"Wheel",
		suffix
	)
	local contactAttachment = nil
	if suspensionConfig.wheel then
		contactAttachment = WheelVehicleAssembly:_createAttachment(
			wheelLink,
			CFrame.new(0, -suspensionConfig.wheel.radius, 0),
			"Contact",
			suffix
		)
	end

	local suspensionFolder = Instance.new("Configuration")
	suspensionFolder.Name = WheelVehicleConstants.FOLDERS.SUSPENSION_CONFIG
	suspensionFolder.Parent = topLink

	for attributeName, attributeValue in pairs(suspensionConfig.suspension) do
		suspensionFolder:SetAttribute(attributeName, attributeValue)
	end

	local pivotLink =
		WheelVehicleAssembly:_createAttachment(parent, suspensionConfig.pivotPoint * offset, "Pivot", suffix)

	if debugAnnotationsConfig then
		local linkMappings = {
			[WheelVehicleConstants.POSITIONS.FRONT] = {
				TopLink = debugAnnotationsConfig.frontTopLink,
				MidLink = debugAnnotationsConfig.frontMidLink,
				BottomLink = debugAnnotationsConfig.frontBottomLink,
				WheelLink = debugAnnotationsConfig.frontWheelLink,
				PivotLink = debugAnnotationsConfig.frontPivotLink,
				Contact = debugAnnotationsConfig.contact,
			},
			[WheelVehicleConstants.POSITIONS.REAR] = {
				TopLink = debugAnnotationsConfig.rearTopLink,
				MidLink = debugAnnotationsConfig.rearMidLink,
				BottomLink = debugAnnotationsConfig.rearBottomLink,
				WheelLink = debugAnnotationsConfig.rearWheelLink,
				PivotLink = debugAnnotationsConfig.rearPivotLink,
				Contact = debugAnnotationsConfig.contact,
			},
		}

		local links = {
			TopLink = topLink,
			MidLink = midLink,
			BottomLink = bottomLink,
			WheelLink = wheelLink,
			PivotLink = pivotLink,
			Contact = contactAttachment,
		}

		local suffixKey = suffix:sub(1, 1)
		local mapping = linkMappings[suffixKey]
		if mapping then
			for linkType, linkInstance in pairs(links) do
				local annotation = mapping[linkType]
				if annotation then
					DebugAnnotation:AssignDebuggingInstance(annotation, linkInstance)
					debugAnnotations[#debugAnnotations + 1] = linkInstance
				end
			end
		end
	end

	local springConstraint = Instance.new("SpringConstraint")
	springConstraint.Name = "Spring" .. suffix
	springConstraint.Attachment0 = topLink
	springConstraint.Attachment1 = midLink
	springConstraint.Visible = true
	springConstraint.Radius = suspensionConfig.spring.radius
	springConstraint.Enabled = false
	springConstraint.Parent = springsFolder

	springConstraint:SetAttribute(WheelVehicleAttributes.POSITION, suffix)
	springConstraint:SetAttribute(WheelVehicleAttributes.SUSPENSION_STIFFNESS, suspensionConfig.spring.stiffness)
	springConstraint:SetAttribute(WheelVehicleAttributes.SUSPENSION_DAMPING, suspensionConfig.spring.damping)

	if suspensionConfig.wheel then
		WheelVehicleAssembly:_createWheel(
			wheelsFolder,
			wheelLink,
			suspensionConfig.wheelCFrameRelative,
			suspensionConfig.wheel,
			suffix
		)
	end
end

--[=[
	Creates a suspension point (attachment) relative to the parent part.
	@param parent BasePart -- The parent part to attach the link to
	@param CFrameRelative CFrame -- The relative CFrame for the link
	@param prefix string -- Prefix for naming the link
	@param suffix string -- Suffix for naming the link
	@return Attachment -- The created attachment
]=]
function WheelVehicleAssembly:_createAttachment(
	parent: BasePart,
	CFrameRelative: CFrame,
	prefix: string,
	suffix: string
): Attachment
	-- Create a link part relative to the parent part
	local link = Instance.new("Attachment")
	link.Name = prefix .. "Link" .. suffix
	link.CFrame = CFrameRelative
	-- link.Visible = true
	link.Parent = parent

	link:SetAttribute(WheelVehicleAttributes.POSITION, suffix)

	return link
end

--[=[
	Creates a wheel part with proper constraints relative to the parent attachment.
	@param parent Attachment -- The parent attachment to attach the wheel to
	@param wheelConfig WheelVehicleTypes.WheelConfig -- The wheel configuration
	@param suffix string -- Suffix for naming the wheel
	@return Part -- The created wheel part
]=]
function WheelVehicleAssembly:_createWheel(
	parent: Folder,
	parentAttachment: Attachment,
	CFrameRelative: CFrame,
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
	-- wheel.CFrame = parentAttachment.WorldCFrame * CFrameRelative
	wheel.CanCollide = false
	wheel.Massless = true
	wheel.Shape = Enum.PartType.Cylinder
	wheel.TopSurface = Enum.SurfaceType.Smooth
	wheel.BottomSurface = Enum.SurfaceType.Smooth

	if CFrameRelative.Position.X < 0 then
		wheel.RightSurface = Enum.SurfaceType.Hinge
	else
		wheel.LeftSurface = Enum.SurfaceType.Hinge
	end

	wheel:SetAttribute(WheelVehicleAttributes.POSITION, suffix)

	local rigidAttachment = Instance.new("Attachment")
	rigidAttachment.Name = "RigidAttachment"
	rigidAttachment.Parent = wheel
	rigidAttachment.CFrame = CFrame.new()

	local rigidConstraint = Instance.new("RigidConstraint")
	rigidConstraint.Name = "RigidConstraint"
	rigidConstraint.Attachment0 = parentAttachment
	rigidConstraint.Attachment1 = rigidAttachment
	rigidConstraint.Parent = wheel

	wheel.Parent = parent

	return wheel
end

return WheelVehicleAssembly
