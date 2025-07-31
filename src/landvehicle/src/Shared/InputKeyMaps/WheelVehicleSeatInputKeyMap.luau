--[=[
	Test input key map provider
	@class TestInputKeyMap
]=]
local require = require(script.Parent.loader).load(script)

local InputKeyMap = require("InputKeyMap")
local InputKeyMapList = require("InputKeyMapList")
local InputKeyMapListProvider = require("InputKeyMapListProvider")
local InputModeTypes = require("InputModeTypes")
local SlottedTouchButtonUtils = require("SlottedTouchButtonUtils")

return InputKeyMapListProvider.new(script.Name, function(self)
	self:Add(InputKeyMapList.new("SIT", {
		InputKeyMap.new(InputModeTypes.KeyboardAndMouse, { Enum.KeyCode.F }),
		InputKeyMap.new(InputModeTypes.Gamepads, { Enum.KeyCode.ButtonA }),
		InputKeyMap.new(InputModeTypes.Touch, { SlottedTouchButtonUtils.createSlottedTouchButton("primary3") }),
	}, {
		bindingName = "Sit",
		rebindable = true,
	}))

	self:Add(InputKeyMapList.new("EXIT", {
		InputKeyMap.new(InputModeTypes.KeyboardAndMouse, { Enum.KeyCode.F }),
		InputKeyMap.new(InputModeTypes.Gamepads, { Enum.KeyCode.ButtonA }),
		InputKeyMap.new(InputModeTypes.Touch, { SlottedTouchButtonUtils.createSlottedTouchButton("primary3") }),
	}, {
		bindingName = "Exit",
		rebindable = true,
	}))
end)
