--!strict
--[=[
	Holds constants for generic engines.
	@class EngineConstants
]=]

local require = require(script.Parent.loader).load(script)

local Table = require("Table")

export type EngineConfig = {}

return Table.readonly({
	DEFAULT_CONFIG = {
		-- Add default engine configuration here
	} :: EngineConfig,
})
