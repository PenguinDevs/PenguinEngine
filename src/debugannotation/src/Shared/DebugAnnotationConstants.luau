--!strict
--[=[
	Holds constants for the wheel-based vehicle class.
	@class WheelVehicleConstants
]=]

local require = require(script.Parent.loader).load(script)

local Table = require("Table")

return Table.readonly({
	Names = {
		Folder = "DebugAnnotations",
		Instance = "Instance",
		UseConstraint = "UseConstraint",
		EnableAnnotations = "EnableAnnotations",
	},
})
