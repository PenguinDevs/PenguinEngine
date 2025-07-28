--!strict
--[=[
    Holds types for the wheel-based vehicle class.
    @class WheelVehicleTypes
]=]

local require = require(script.Parent.loader).load(script)

local DebugAnnotation = require("DebugAnnotation")
-- local EngineConstants = require("EngineConstants")

export type WheelConfig = {
	radius: number,
	span: number,
}

export type SuspensionTypes = "MacPhersonStrut" | "MultiLink"

export type SuspensionConfig = {
	position: Positions,
	topLinkCFrameRelative: CFrame, -- Relative to the PrimaryPart of the vehicle of the top link
	midLinkCFrameRelative: CFrame, -- Relative to the top link
	bottomLinkCFrameRelative: CFrame, -- Relative to the mid link
	pivotPoint: CFrame, -- The pivot point of the wheel hub's control arm(s)
	wheelCFrameRelative: CFrame, -- Relative to the bottom link of the suspension
	spring: {
		stiffness: number,
		damping: number,
		radius: number,
	},
	suspension: any,
	wheel: WheelConfig?,
}

export type WheelVehicleConfig = {
	chassis: ChassisConfig,
	-- engine: EngineConstants.EngineConfig,
	suspensions: { SuspensionConfig },
}

export type ChassisConfig = {
	mass: number, -- Mass of the chassis in kg
	massSize: Vector3, -- Expected size of the chassis in studs
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
	frontPivotLink: DebugAnnotation.AnnotationObject,
	rearTopLink: DebugAnnotation.AnnotationObject,
	rearMidLink: DebugAnnotation.AnnotationObject,
	rearBottomLink: DebugAnnotation.AnnotationObject,
	rearWheelLink: DebugAnnotation.AnnotationObject,
	rearPivotLink: DebugAnnotation.AnnotationObject,
}

export type Positions = "FL" | "FR" | "RL" | "RR"

return {}
