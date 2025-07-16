--!strict
--[=[
	@class DebugannotationsServiceClient
]=]

local require = require(script.Parent.loader).load(script)

local ServiceBag = require("ServiceBag")

local DebugannotationsServiceClient = {}
DebugannotationsServiceClient.ServiceName = "DebugannotationsServiceClient"

function DebugannotationsServiceClient:Init(serviceBag: ServiceBag.ServiceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")


end

return DebugannotationsServiceClient