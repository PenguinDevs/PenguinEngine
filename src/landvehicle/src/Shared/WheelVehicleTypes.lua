--!strict
--[=[
    Holds types for the wheel-based vehicle class.
    @class WheelVehicleTypes
]=]

local require = require(script.Parent.loader).load(script)

local EngineConstants = require("EngineConstants")

export type WheelConfig = {
	CFrameRelative: CFrame, -- Relative to the bottom link of the suspension
	radius: number,
	span: number,
}

export type SuspensionConfig = {
	topLinkCFrameRelative: CFrame, -- Relative to the PrimaryPart of the vehicle of the top link
	midLinkCFrameRelative: CFrame, -- Relative to the top link
	bottomLinkCFrameRelative: CFrame, -- Relative to the mid link
	spring: {
		stiffness: number,
		damping: number,
	},
	wheel: WheelConfig?,
}

export type WheelVehicleConfig = {
	engine: EngineConstants.EngineConfig,
	suspensions: { SuspensionConfig },
}

return {}
