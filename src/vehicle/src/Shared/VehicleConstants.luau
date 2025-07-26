--!strict
--[=[
	Holds constants for the vehicle class.
	@class VehicleConstants
]=]

local require = require(script.Parent.loader).load(script)

local Table = require("Table")

return Table.readonly({
	PRIMARY_PART_COLOUR = Color3.fromRGB(255, 0, 0),
	DEBUGGING_COLOUR = Color3.fromRGB(0, 255, 0),
	VEHICLE_MODEL_OBJ_VAL_NAME = "VehicleModelObj",
})
