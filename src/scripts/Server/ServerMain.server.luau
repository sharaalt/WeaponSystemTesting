--[[
	@class ServerMain
]]
local ServerScriptService = game:GetService("ServerScriptService")

local root = ServerScriptService.WeaponSystemIteration4
local loader = root:FindFirstChild("LoaderUtils", true).Parent
local require = require(loader).bootstrapGame(root)

local NevermoreTestRunnerUtils = require("NevermoreTestRunnerUtils")

if NevermoreTestRunnerUtils.runTestsIfNeededAsync(root.game) then
	return
end

local serviceBag = require("ServiceBag").new()
serviceBag:GetService(require("WeaponSystemIteration4Service"))
serviceBag:Init()
serviceBag:Start()
