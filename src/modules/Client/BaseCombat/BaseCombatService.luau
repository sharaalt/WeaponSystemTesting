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
		self:_generateTools()
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
	-- A little bit of an easier way to access the player.
	local Player: Player = self._Player

	-- Our little table of expandable state variables :-)
	local initVariables = {
		[BaseCombatServiceConstants.EQUIPPING_STATE_NAME] = false,
		Unequipping = false,
		Reloading = false,
		Aiming = false,
		Inspecting = false,
		Firing = false,

		-- Animation States
		-- Animations = {
		-- 	IdleAnim = nil,
		-- },
	}

	-- Character Signals
	self._maid:GiveTask(Player.Backpack.ChildAdded:Connect(function(a0: Instance)
		self:_getWeapons()
	end))

	self._maid:GiveTask(Player.Backpack.ChildAdded:Connect(function(a0: Instance)
		self:_getWeapons()
	end))

	-- Equipping Functionality
	self._maid:GiveTask(self._BaseCombatInput.WeaponEquipped:Connect(function(number)
		if self._ActiveWeapon then
			warn("[BaseCombatService] - There's already an active weapon in use.")
			return
		end

		local WeaponData = self:_getWeaponData(number)

		-- Finish off initalizing the states table and set it as the active weapon.
		local states: Types.StateData = self:_initWeaponTbl(initVariables)
		states._weaponData = WeaponData
		self._ActiveWeapon = states

		-- Update the state value to true to prevent sudden unequips.
		self._StateManager:UpdateStateValue(states._states.Equipping.StateName, true)

		-- Attach the model and begin the equip animation.
		self._ViewmodelHelper:AttachViewmodel(WeaponData.WeaponName)
		self._ViewmodelHelper:PlayAnimation(WeaponData.WeaponEquipAnim, function()
			self._StateManager:UpdateStateValue(states._states.Equipping.StateName, false)
		end)
	end))

	-- Unequipping Functionality
	self._maid:GiveTask(self._BaseCombatInput.WeaponUnequipping:Connect(function(number)
		if self._ActiveWeapon == nil then
			warn("[BaseCombatService] - Cannot unequip nothing.")
			return
		end

		-- Check's tagged weapons to see if we're unequipping the correct one.
		local WeaponData = self:_getWeaponData(number)
		local weaponName = WeaponData.WeaponName

		-- Check if the names match.
		if self._ActiveWeapon._weaponData.WeaponName == weaponName then
			if self:_checkStateVariables() then
				warn("[BaseCombatService] - A state is active at this time cannot preform action.")
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
	end))

	-- Firing Functionality
	self._maid:GiveTask(self._BaseCombatInput.WeaponFired:Connect(function()
		-- If there's no active weapon don't bother.
		if self._ActiveWeapon == nil then
			warn("[BaseCombatService] - No weapon equipped cannot proceed.")
			return
		end

		-- If any variable is active return.
		if self:_checkStateVariables() then
			warn("[BaseCombatService] - A state is active at this time cannot preform action.")
			return
		end

		-- Retrieve's the weapon data and make's it a bit easier to access/work with :-]
		local WeaponData = self._ActiveWeapon

		print(WeaponData)

		self._StateManager:UpdateStateValue(WeaponData._states.Firing.StateName, true)

		self._ViewmodelHelper:PlayAnimation(WeaponData._weaponData.WeaponFireAnim, function()
			self._StateManager:UpdateStateValue(WeaponData._states.Firing.StateName, false)
		end)
	end))

	-- Inspecting Functionality
	self._maid:GiveTask(self._BaseCombatInput.WeaponInspected:Connect(function()
		-- If there's no active weapon don't bother.
		if self._ActiveWeapon == nil then
			warn("[BaseCombatService] - No weapon equipped cannot proceed.")
			return
		end

		-- If any variable is active return.
		if self:_checkStateVariables() then
			warn("[BaseCombatService] - A state is active at this time cannot preform action.")
			return
		end

		local WeaponData = self._ActiveWeapon

		self._StateManager:UpdateStateValue(WeaponData._states.Inspecting.StateName, true)

		self._ViewmodelHelper:PlayAnimation(WeaponData._weaponData.WeaponInspectAnim, function()
			self._StateManager:UpdateStateValue(WeaponData._states.Inspecting.StateName, false)
		end)
	end))

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
	for _, value in pairs(stateValues) do
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
	Retrieve's a weapons data based off there index inside the tagged weapons table.

	@param index number -- The index of weaponData you want to find.

	@return {}
]]
function BaseCombatService:_getWeaponData(index: number): {}
	-- A bit of type checking.
	if typeof(index) ~= "number" then
		warn(string.format("[BaseCombatService] - Type of index %q is not a valid type.", typeof(index)))
		return
	end

	-- The main loop.
	for i, v in pairs(self._TaggedWeapons) do
		-- If the index's match we return the data.
		if index == i then
			return v.WeaponData
		end
	end

	warn(string.format("[BaseCombatService] - Could not find weaponData at index %i", index))
	return nil
end

--[[
	Generate's viewmodel's into tools.

	@return ()
]]
function BaseCombatService:_generateTools(): ()
	-- Some variables that I needed.
	local ViewmodelPath = game.ReplicatedStorage.Shared.Viewmodels
	local Player: Player = self._Player
	local Backpack = Player.Backpack

	for _, v in pairs(ViewmodelPath:GetChildren()) do
		print(v)
		local newTool = Instance.new("Tool")
		newTool.Name = v.Name
		newTool.Parent = Backpack
		newTool:AddTag("Weapon")

		print(newTool)
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
