--[[
	@class ClientMain
]]
local loader = game:GetService("ReplicatedStorage"):WaitForChild("WeaponSystemIteration4"):WaitForChild("loader")
local require = require(loader).bootstrapGame(loader.Parent)

local serviceBag = require("ServiceBag").new()

-- Packages
local BaseCombatClass = serviceBag:GetService(require("BaseCombat"))

serviceBag:GetService(require("WeaponSystemIteration4ServiceClient"))
serviceBag:Init()
serviceBag:Start()
