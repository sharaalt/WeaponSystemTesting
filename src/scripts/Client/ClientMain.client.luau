--[[
	@class ClientMain
]]
local loader = game:GetService("ReplicatedStorage"):WaitForChild("ReadyOrNotRoblox"):WaitForChild("loader")
local require = require(loader).bootstrapGame(loader.Parent)

local serviceBag = require("ServiceBag").new()
local LocalPlayer = game:GetService("Players").LocalPlayer

-- Packages
local BaseCombatClass = serviceBag:GetService(require("BaseCombat"))

serviceBag:GetService(require("ReadyOrNotRobloxServiceClient"))
serviceBag:Init()
serviceBag:Start()
