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
local BaseCombatServiceConstants = require(script.Parent.Parent.Parent.Shared.Modules.BaseCombatServiceConstants)
local StateManager = require(script.Parent.Parent.StateManager)
local ViewmodelHelper = require(script.Parent.ViewmodelHelper)
local Players = game:GetService("Players")

local Types = require(script.Parent.Types)
local loader = require(script.Parent.Parent.loader)
local require = loader.load(script)

-- Internal Services
local Brio = require("Brio")
local Maid = require("Maid")
-- local Signal = require("Signal")

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
	self._TaggedWeapons = {} :: { [number]: Types.WeaponTable }
	self._ActiveWeapon = nil :: Types.StateData?

	-- Services
	self._maid = Maid.new()
	self._BaseCombatInput = BaseCombatInput.new()
	self._ViewmodelHelper = ViewmodelHelper.new(self._Player)
	self._StateManager = StateManager.new()

	-- Initalize the main loop and grab tagged weapons.
	self._maid:GiveTask(task.spawn(function()
		self:_getWeapons()
		self:_mainLoop()
	end))
end

-- ==================
-- === Public API ===
-- ==================
--[[
    The main loop of the service.
    
    @return ()
]]
function BaseCombatService:_mainLoop(): ()
	-- Our little table of expandable state variables :-)
	local initVariables = {
		BaseCombatServiceConstants.EQUIPPING_STATE_NAME = false,
		Unequipping = false,
		Reloading = false,
		Aiming = false,
		Inspecting = false,

		-- Animation States
		-- Animations = {
		-- 	IdleAnim = nil,
		-- },
	}

	-- Equipping Functionality
	self._maid:GiveTask(self._BaseCombatInput.WeaponEquipped:Connect(function(number)
		for i, v in ipairs(self._TaggedWeapons) do
			if i == number then
				if self._ActiveWeapon then
					warn("[BaseCombatService] - There's already an active weapon in use.")
					return
				end

				-- Finish off initalizing the states table and set it as the active weapon.
				local states: Types.StateData = self:_initWeaponTbl(initVariables)
				states._weaponData = v.WeaponData
				self._ActiveWeapon = states

				-- Update the state value to true to prevent sudden unequips.
				self._StateManager:UpdateStateValue(states._states.Equipping.StateName, true)

				-- Attach the model and begin the equip animation.
				self._ViewmodelHelper:AttachViewmodel(v.Tool.Name)
				self._ViewmodelHelper:PlayAnimation(v.WeaponData.WeaponEquipAnim, function()
					self._StateManager:UpdateStateValue(states._states.Equipping.StateName, false)
				end)
			end
		end
	end))

	-- Unequipping Functionality
	self._maid:GiveTask(self._BaseCombatInput.WeaponUnequipping:Connect(function(number)
		-- Check's tagged weapons to see if we're unequipping the correct one.
		for i, v in ipairs(self._TaggedWeapons) do
			if i == number then
				local weaponName = v.WeaponData.WeaponName

				-- Check if the names match.
				if self._ActiveWeapon._weaponData.WeaponName == weaponName then
					if self:_checkStateVariables() then
						warn("[BaseWeaponService] - A state is active at this time cannot preform action.")
						return
					end

					-- self._StateManager:UpdateStateValue(, _)

					-- Assuming the animation has a destroy event we destroy it a bit early to prevent visibility.
					self._ViewmodelHelper:PlayAnimationWithEvent(
						self._ActiveWeapon._weaponData.WeaponUnequipAnim,
						"DestroyModel",
						function()
							-- Cleanup callback.
							self._ActiveWeapon._stateBrio:Kill()
							self._ActiveWeapon = nil
							self._ViewmodelHelper:DetachViewmodel()
						end
					)
				end
			end
		end
	end))

	-- Firing Functionality
	self._maid:GiveTask(self._BaseCombatInput.WeaponFired:Connect(function()
		-- Add a function to determine if any of the variables are true.

		self._ViewmodelHelper:PlayAnimation("a", "a")
	end))

	-- Inspecting Functionality

	-- Reloading Functionality
end

-- ==================
-- === Private API ==
-- ==================
--[[
    Retrives all the tools in StarterPack with the "Weapon" tag.

    @return ()
]]
function BaseCombatService:_getWeapons(): ()
	local _Character = self._Player.Character or self._Player.CharacterAdded:Wait() -- Wait for the character to actually be loaded before accessing there backpack.

	local slotCounter = 1

	for _, v in ipairs(self._Player.Backpack:GetChildren()) do
		if v:IsA("Tool") then
			if v:HasTag("Weapon") then -- Only pickup tool's tagged with "Weapon"
				local WeaponData = game.ReplicatedStorage.Shared.WeaponData:FindFirstChild(v.Name)

				-- A little bit of error handling.
				if WeaponData == nil then
					warn(string.format("[BaseCombatService] - Could not find a module for weapon %q", v.Name))
				else
					self._TaggedWeapons[slotCounter] = BaseCombatProfile.FormatTable(v, WeaponData) -- Cache tagged weapons in a formatted table.
					slotCounter += 1
				end
			end
		end
	end
end

--[[
	Initalizes the activeWeapon table.

	@param variables {boolean} - The table of booleans and variable name's to initalize the table.

	@return ()
]]
function BaseCombatService:_initWeaponTbl(variables: { boolean }): Types.StateData
	-- The base component of the binded states.
	local BindedStates: Types.StateData = {
		_weaponData = {},
		_states = {},
	}

	-- Maid setup
	local WeaponMaid = Maid.new()

	-- Brio setup
	BindedStates._stateBrio = Brio.new(BindedStates)

	-- Whenever the brio dies we clean up and remove the states.
	WeaponMaid:GiveTask(BindedStates._stateBrio:GetDiedSignal():Connect(function()
		for j, _ in pairs(BindedStates._states) do
			self._StateManager:RemoveState(j)
		end

		WeaponMaid:DoCleaning()
	end))

	-- Everytime we create a state we use the StateCreated signal to retrive it.
	WeaponMaid:GiveTask(self._maid:GiveTask(self._StateManager.StateCreated:Connect(function(stateName, stateTable)
		-- If the state brio is dead don't bother adding new state's onto a dead brio.
		if BindedStates._stateBrio:IsDead() then
			return
		end

		for i, _ in pairs(variables) do
			if i == stateName then
				-- Bind it to the table.
				BindedStates._states[stateName] = stateTable
				break
			end
		end
	end)))

	-- Loop's through the variables and binds them.
	for i, v in pairs(variables) do
		self._StateManager:AddState(i, v)
	end

	return BindedStates
end

--[[
	Determines if any variable in the states are true.

	@return boolean
]]
function BaseCombatService:_checkStateVariables(): boolean
	-- Counter
	local trueVariables = 0

	-- States
	local stateValues: { [string]: boolean } = self._ActiveWeapon._states

	-- Determines if any variable in the state pool is true.
	for i, value in pairs(stateValues) do
		print(i, value)
		if value.StateValue then
			trueVariables += 1
		end
	end

	-- If more than 0 variables are true than we return else we throw false.
	if trueVariables > 0 then
		return true
	else
		return false
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
