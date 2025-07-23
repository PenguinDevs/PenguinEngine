--!strict
--[=[
    Holds types for the wheel-based vehicle class.
    @class WheelVehicleTypes
]=]

local require = require(script.Parent.loader).load(script)

local DebugAnnotation = require("DebugAnnotation")
local EngineConstants = require("EngineConstants")

export type WheelConfig = {
	radius: number,
	span: number,
}

export type SuspensionConfig = {
	topLinkCFrameRelative: CFrame, -- Relative to the PrimaryPart of the vehicle of the top link
	midLinkCFrameRelative: CFrame, -- Relative to the top link
	bottomLinkCFrameRelative: CFrame, -- Relative to the mid link
	wheelCFrameRelative: CFrame, -- Relative to the bottom link of the suspension
	spring: {
		stiffness: number,
		damping: number,
		radius: number,
	},
	wheel: WheelConfig?,
}

export type WheelVehicleConfig = {
	engine: EngineConstants.EngineConfig,
	suspensions: { SuspensionConfig },
}

export type SuspensionCustomisation = {
	camber: number,
	caster: number,
	kpi: number, -- Kingpin inclination
	toeIn: number,
}

export type WheelVehicleCustomisation = {
	suspensions: {
		Front: SuspensionCustomisation,
		Rear: SuspensionCustomisation,
	},
}

export type WheelVehicleAnnotations = {
	contact: DebugAnnotation.AnnotationObject,
	frontTopLink: DebugAnnotation.AnnotationObject,
	frontMidLink: DebugAnnotation.AnnotationObject,
	frontBottomLink: DebugAnnotation.AnnotationObject,
	frontWheelLink: DebugAnnotation.AnnotationObject,
	rearTopLink: DebugAnnotation.AnnotationObject,
	rearMidLink: DebugAnnotation.AnnotationObject,
	rearBottomLink: DebugAnnotation.AnnotationObject,
	rearWheelLink: DebugAnnotation.AnnotationObject,
}

return {}
