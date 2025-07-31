--[=[
	Wheel vehicle driver input key map provider
	@class WheelVehicleDriverInputKeyMap
]=]
local require = require(script.Parent.loader).load(script)

local InputKeyMap = require("InputKeyMap")
local InputKeyMapList = require("InputKeyMapList")
local InputKeyMapListProvider = require("InputKeyMapListProvider")
local InputModeTypes = require("InputModeTypes")
local SlottedTouchButtonUtils = require("SlottedTouchButtonUtils")

return InputKeyMapListProvider.new(script.Name, function(self)
	self:Add(InputKeyMapList.new("STEER_LEFT", {
		InputKeyMap.new(InputModeTypes.KeyboardAndMouse, { Enum.KeyCode.A }),
		InputKeyMap.new(InputModeTypes.Touch, { SlottedTouchButtonUtils.createSlottedTouchButton("primary1") }),
	}, {
		bindingName = "Steer Left",
		rebindable = true,
	}))

	self:Add(InputKeyMapList.new("STEER_RIGHT", {
		InputKeyMap.new(InputModeTypes.KeyboardAndMouse, { Enum.KeyCode.D }),
		InputKeyMap.new(InputModeTypes.Touch, { SlottedTouchButtonUtils.createSlottedTouchButton("primary2") }),
	}, {
		bindingName = "Steer Right",
		rebindable = true,
	}))

	self:Add(InputKeyMapList.new("ACCELERATE", {
		InputKeyMap.new(InputModeTypes.KeyboardAndMouse, { Enum.KeyCode.W }),
		InputKeyMap.new(InputModeTypes.Touch, { SlottedTouchButtonUtils.createSlottedTouchButton("primary3") }),
	}, {
		bindingName = "Accelerate",
		rebindable = true,
	}))

	self:Add(InputKeyMapList.new("BRAKE", {
		InputKeyMap.new(InputModeTypes.KeyboardAndMouse, { Enum.KeyCode.S }),
		InputKeyMap.new(InputModeTypes.Touch, { SlottedTouchButtonUtils.createSlottedTouchButton("primary4") }),
	}, {
		bindingName = "Brake",
		rebindable = true,
	}))
end)
