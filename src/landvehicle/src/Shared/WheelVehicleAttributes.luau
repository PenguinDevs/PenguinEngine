--!strict
--[=[
	Holds attributes for the wheel-based vehicles.
	@class WheelVehicleAttributes
]=]

local require = require(script.Parent.loader).load(script)

local Table = require("Table")

return Table.readonly({
	POSITION = "Position",
	SUSPENSION_STIFFNESS = "Stiffness",
	SUSPENSION_DAMPING = "Damping",
})
