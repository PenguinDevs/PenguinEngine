--!strict
--[=[
    Utility functions for wheel-based vehicles.
    @class WheelVehicleUtils
]=]

local require = require(script.Parent.loader).load(script)

local CFrameUtils = require("CFrameUtils")
local WheelVehicleTypes = require("WheelVehicleTypes")

local WheelVehicleUtils = {}

--[=[
    Ensures the top, mid, bottom links and wheel faces to its corresponding child.
    @param suspensionConfig WheelVehicleTypes.SuspensionConfig
]=]
function WheelVehicleUtils.ensureLinksAndWheelsFaceChildren(suspensionConfig: WheelVehicleTypes.SuspensionConfig)
	local topLink = suspensionConfig.topLinkCFrameRelative.Position
	local midLink = suspensionConfig.topLinkCFrameRelative * suspensionConfig.midLinkCFrameRelative.Position - topLink
	local bottomLink = suspensionConfig.topLinkCFrameRelative
			* suspensionConfig.midLinkCFrameRelative
			* suspensionConfig.bottomLinkCFrameRelative.Position
		- topLink
		- midLink

	local topToMidAngledCFrame = CFrame.lookAt(Vector3.new(0, 0, 0), midLink)
	local midToBottomAngledCFrame = CFrame.lookAt(Vector3.new(0, 0, 0), bottomLink)

	-- Orient top link to look at mid link
	suspensionConfig.topLinkCFrameRelative = CFrame.new(topLink) * topToMidAngledCFrame

	-- Orient mid link to look at bottom link
	suspensionConfig.midLinkCFrameRelative = CFrame.new(0, 0, -midLink.Magnitude)
		* topToMidAngledCFrame:Inverse()
		* midToBottomAngledCFrame

	suspensionConfig.bottomLinkCFrameRelative = CFrame.new(0, 0, -bottomLink.Magnitude)
		* midToBottomAngledCFrame:Inverse()

	-- if mirrorSide then
	-- 	suspensionConfig.topLinkCFrameRelative =
	-- 		CFrameUtils.mirror(suspensionConfig.topLinkCFrameRelative, topLink, Vector3.new(-1, 0, 0))
	-- 	suspensionConfig.midLinkCFrameRelative = CFrameUtils.mirror(
	-- 		suspensionConfig.midLinkCFrameRelative,
	-- 		Vector3.new(0, 0, 0),
	-- 		Vector3.new(-1, 0, 0)
	-- 	) * CFrame.Angles(0, math.rad(180), 0)
	-- 	suspensionConfig.bottomLinkCFrameRelative =
	-- 		CFrameUtils.mirror(suspensionConfig.bottomLinkCFrameRelative, Vector3.new(0, 0, 0), Vector3.new(-1, 0, 0))
	-- end
end

--[=[
	Flips the links and wheels of the suspension config across the Z-axis.
	@param suspensionConfig WheelVehicleTypes.SuspensionConfig
]=]
function WheelVehicleUtils.flipLinksAndWheels(suspensionConfig: WheelVehicleTypes.SuspensionConfig)
	local topLink = suspensionConfig.topLinkCFrameRelative.Position
	local midLink = suspensionConfig.topLinkCFrameRelative * suspensionConfig.midLinkCFrameRelative.Position - topLink
	local bottomLink = suspensionConfig.midLinkCFrameRelative * suspensionConfig.bottomLinkCFrameRelative.Position
		- midLink

	local topLinkOpposite = CFrameUtils.mirror(CFrame.new(topLink), Vector3.new(0, 0, 0), Vector3.new(1, 0, 0)).Position
	local midLinkOpposite = CFrameUtils.mirror(CFrame.new(midLink), Vector3.new(0, 0, 0), Vector3.new(1, 0, 0)).Position
	local bottomLinkOpposite =
		CFrameUtils.mirror(CFrame.new(bottomLink), Vector3.new(0, 0, 0), Vector3.new(1, 0, 0)).Position

	local pivotLinkOpposite = CFrameUtils.mirror(
		CFrame.new(suspensionConfig.pivotPoint.Position),
		Vector3.new(0, 0, 0),
		Vector3.new(1, 0, 0)
	).Position

	suspensionConfig.topLinkCFrameRelative = CFrame.new(topLinkOpposite)
	suspensionConfig.midLinkCFrameRelative = CFrame.new(midLinkOpposite)
	suspensionConfig.bottomLinkCFrameRelative = CFrame.new(bottomLinkOpposite)

	suspensionConfig.pivotPoint = CFrame.new(pivotLinkOpposite)

	if suspensionConfig.wheel then
		local wheel = suspensionConfig.wheelCFrameRelative.Position
		local wheelOpposite = CFrameUtils.mirror(CFrame.new(wheel), Vector3.new(0, 0, 0), Vector3.new(1, 0, 0)).Position
		suspensionConfig.wheelCFrameRelative = CFrame.new(wheelOpposite)
	end
end

return WheelVehicleUtils
