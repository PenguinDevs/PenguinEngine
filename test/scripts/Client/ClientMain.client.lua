--[[
	@class ClientMain
]]
local loader = game:GetService("ReplicatedStorage"):WaitForChild("landvehicle"):WaitForChild("loader")
local require = require(loader).bootstrapGame(loader.Parent)

local serviceBag = require("ServiceBag").new()
serviceBag:GetService(require("LandvehicleServiceClient"))
serviceBag:Init()
serviceBag:Start()
