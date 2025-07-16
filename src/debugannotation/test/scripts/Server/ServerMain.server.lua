--[[
	@class ServerMain
]]
local ServerScriptService = game:GetService("ServerScriptService")

local loader = ServerScriptService:FindFirstChild("LoaderUtils", true).Parent
local require = require(loader).bootstrapGame(ServerScriptService.debugannotations)

local serviceBag = require("ServiceBag").new()
serviceBag:GetService(require("DebugannotationsService"))
serviceBag:Init()
serviceBag:Start()