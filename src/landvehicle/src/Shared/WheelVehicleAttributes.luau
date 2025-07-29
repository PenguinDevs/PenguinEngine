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
	SUSPENSION_EXTRA_LENGTH = "ExtraLength",
	MASS = "Mass",
	MASS_SIZE = "MassSize",
	MASS_OFFSET = "MassOffset",
	ADHESION_COEFFICIENT = "AdhesionCoefficient",
})
