--!strict
--[=[
	@class DebugannotationsService
]=]

local require = require(script.Parent.loader).load(script)

local ServiceBag = require("ServiceBag")

local DebugannotationsService = {}
DebugannotationsService.ServiceName = "DebugannotationsService"

function DebugannotationsService:Init(serviceBag: ServiceBag.ServiceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")

	-- Internal
	self._serviceBag:GetService(require("DebugAnnotationParent"))
end

return DebugannotationsService
