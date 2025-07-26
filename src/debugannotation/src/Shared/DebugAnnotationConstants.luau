--!strict
--[=[
	Holds constants for the wheel-based vehicle class.
	@class WheelVehicleConstants
]=]

local require = require(script.Parent.loader).load(script)

local Table = require("Table")

return Table.readonly({
	NAMES = {
		FOLDER = "DebugAnnotations",
		INSTANCE = "Instance",
		USE_CONSTRAINT = "UseConstraint",
		ENABLE_ANNOTATIONS = "EnableAnnotations",
	},
})
