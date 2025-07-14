--[[
	@class ServerMain
]]
local ServerScriptService = game:GetService("ServerScriptService")

local loader = ServerScriptService:FindFirstChild("LoaderUtils", true).Parent
local require = require(loader).bootstrapGame(ServerScriptService.landvehicles)

local serviceBag = require("ServiceBag").new()
serviceBag:GetService(require("LandvehiclesService"))
serviceBag:Init()
serviceBag:Start()