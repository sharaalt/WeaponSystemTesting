--[[
    @author sharafzada 
    @class BaseCombatService.luau
    @version 1.0.0

	-- To-do list
	@todo A lot TwT

    BaseCombat service is meant to handle everything related to weapon combat and act's as an ocestrator between the multiple different sub-services/classes in the BaseCombat 
	folder. Ideally BaseCombatService should be kept realtively lean to allow for both readability and modularity when updating code or refactoring.
]]

-- External Services
local BaseCombatInput = require(script.Parent.BaseCombatInput)
local BaseCombatProfile = require(script.Parent.BaseCombatProfile)
local ViewmodelHelper = require(script.Parent.ViewmodelHelper)
local Players = game:GetService("Players")

local loader = require(script.Parent.Parent.loader)
local require = loader.load(script)

-- Internal Services
local Maid = require("Maid")
local Signal = require("Signal")

local BaseCombatService = {}
BaseCombatService.ServiceName = "BaseCombatService"

--[[
    @param serviceBag any -- The serviceBag used for initalization.
    @return ()
]]
function BaseCombatService:Init(serviceBag): ()
	assert(not self._serviceBag, "[BaseCombatService] - BaseCombatService is already initalized!")
	self._serviceBag = assert(serviceBag, "[BaseCombatService] - BaseCombatService is already initalized!")

	-- Variables
	self._Player = Players.LocalPlayer
	self._TaggedWeapons = {}
	self._ActiveWeapon = {}

	-- Services
	self._maid = Maid.new()
	self._BaseCombatInput = BaseCombatInput.new()
	self._ViewmodelHelper = ViewmodelHelper.new(self._Player)

	-- Initalize the main loop and grab tagged weapons.
	self._maid:GiveTask(task.spawn(function()
		self:_getWeapons()
		self:_mainLoop()
	end))
end

-- =======================
-- ===== Private API =====
-- =======================
--[[
    The main loop of the service.
    
    @return ()
]]
function BaseCombatService:_mainLoop(): ()
	-- Equipping Functionality
	self._maid:GiveTask(self._BaseCombatInput.WeaponEquipped:Connect(function(number)
		for i, v in ipairs(self._TaggedWeapons) do
			if i == number then
				v.WeaponData.Equipped = true
				self._ViewmodelHelper:AttachViewmodel(v.Tool.Name)
				self._ViewmodelHelper:PlayAnimation(v.WeaponData.WeaponEquipAnim)
			end
		end
	end))

	-- Unequipping Functionality
	self._maid:GiveTask(self._BaseCombatInput.WeaponUnequipping:Connect(function(number)
		for i, v in ipairs(self._TaggedWeapons) do
			if i == number then
				v.WeaponData.Equipped = false
				self._ViewmodelHelper:DetachViewmodel()
			end
		end
	end))
end

--[[
    Retrives all the tools in StarterPack with the "Weapon" tag.

    @return ()
]]
function BaseCombatService:_getWeapons(): ()
	local _Character = self._Player.Character or self._Player.CharacterAdded:Wait() -- Wait for the character to actually be loaded before accessing there backpack.

	for i, v in ipairs(self._Player.Backpack:GetChildren()) do
		if v:IsA("Tool") then
			if v:HasTag("Weapon") then -- Only pickup tool's tagged with "Weapon"
				local WeaponData = game.ReplicatedStorage.Shared.WeaponData:FindFirstChild(v.Name)

				-- A little bit of error handling.
				if WeaponData == nil then
					warn(string.format("[BaseCombatService] - Could not find a module for weapon %q", v.Name))
					return
				end

				self._TaggedWeapons[i] = BaseCombatProfile.FormatTable(v, WeaponData) -- Cache tagged weapons in a formatted table.
			end
		end
	end
end

--[[
    Cleans up the service once destroyed.

    @return ()
]]
function BaseCombatService:Destroy(): ()
	self._maid:DoCleaning()
	print("[BaseCombatService] - Sucessfully destroyed BaseCombatService.")
end

return BaseCombatService
