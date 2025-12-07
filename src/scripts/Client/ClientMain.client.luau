--[[
	@class ClientMain
]]
local loader = game:GetService("ReplicatedStorage"):WaitForChild("ReadyOrNotRoblox"):WaitForChild("loader")
local require = require(loader).bootstrapGame(loader.Parent)

local serviceBag = require("ServiceBag").new()
local LocalPlayer = game:GetService("Players").LocalPlayer

-- Packages
local BaseCombatClass = serviceBag:GetService(require("BaseCombatClass"))

serviceBag:GetService(require("ReadyOrNotRobloxServiceClient"))
serviceBag:Init()
serviceBag:Start()

BaseCombatClass.new(LocalPlayer)
