-- External Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local BaseCombatConstants = require(script.Parent.Parent.Parent.Shared.BaseCombatConstanants)
local StateManagerClass = require(script.Parent.StateManagerClass)
local ViewmodelClass = require(script.Parent.ViewmodelClass)

local loader = require(script.Parent.Parent.loader)
local require = loader.load(script)

-- Internal Services
local Maid = require("Maid")
local Signal = require("Signal")

local BaseCombatService = {}
BaseCombatService.ServiceName = "BaseCombatService"

function BaseCombatService:Init(serviceBag)
	assert(not self._serviceBag, "[BaseCombatService] - Service is already initalized!")

	self._serviceBag = assert(serviceBag, "[BaseCombatService] - Service is already initalized!")

	-- Variables
	self._Weapons = {}
	self._Player = Players.LocalPlayer

	-- Services
	self._maid = Maid.new()
	self._ViewmodelClass = ViewmodelClass.new()
	self._StateManagerClass = StateManagerClass.new()

	-- Signals

	self._maid:GiveTask(task.spawn(function()
		self:_mainLoop()
		self:_SortTools()
	end))
end

-- =======================
-- ===== Private API =====
-- =======================

--[[
	The main loop of the service handles input and classes.

	@return ()
]]
function BaseCombatService:_mainLoop(): ()
	local nums = { -- Used to check keybinds.
		[Enum.KeyCode.One] = 1,
		[Enum.KeyCode.Two] = 2,
		[Enum.KeyCode.Three] = 3,
		[Enum.KeyCode.Four] = 4,
		[Enum.KeyCode.Five] = 5,
		[Enum.KeyCode.Six] = 6,
		[Enum.KeyCode.Seven] = 7,
		[Enum.KeyCode.Eight] = 8,
		[Enum.KeyCode.Nine] = 9,
		[Enum.KeyCode.Zero] = 0,
	}
	local weaponData = nil

	UserInputService.InputBegan:Connect(function(input: InputObject)
		local number = nums[input.KeyCode]
		local binded = self._ViewmodelClass:_isBinded()

		if number then -- Checks if the keycode is a valid number.
			if self._Weapons[number] then -- Checks if that number is cached in the weapons table.
				weaponData = self._Weapons[number]
				local camera = workspace.CurrentCamera

				if binded then -- If the viewmodel is binded unbind it.
					if self:_checkIfTrue(self._StateManagerClass:GetStatesBulk(self._Player)) then
						warn("[BaseCombatClass] - A state is true you cannot unequip at this time.")
						return
					end

					self._ViewmodelClass:PlayViewmodelAnimation(weaponData.Animations.UnEquip, "UnEquipping")

					self._StateManagerClass:SetState(self._Player, "UnEquipping", true)

					local connection = self._ViewmodelClass.AnimationEnded:Once(function(animName)
						self._StateManagerClass:SetState(self._Player, animName, false)
						self._StateManagerClass:RemoteStateTable(self._Player)
						self._ViewmodelClass:UnbindViewmodel()
					end)

					self._maid:GiveTask(connection)
				else -- If it's not binded bind it.
					self._StateManagerClass:CreateStateTable(BaseCombatConstants.GetStates(), self._Player) -- Initalize the state table

					if self:_checkIfTrue(self._StateManagerClass:GetStatesBulk(self._Player)) then -- Lock's out unequipping/other functions.
						warn("[BaseCombatClass] - A state is true you cannot equip at this time.")
						return
					end

					self._StateManagerClass:SetState(self._Player, "Equipping", true) -- Unlocks unequipping/other functions.
					self._ViewmodelClass:BindViewmodel(camera, weaponData.WeaponName)
					self._ViewmodelClass:PlayViewmodelAnimation(weaponData.Animations.Equip, "Equipping")

					local connection = self._ViewmodelClass.AnimationEnded:Once(function(animName)
						self._StateManagerClass:SetState(self._Player, animName, false)
					end)

					self._maid:GiveTask(connection)
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.R then -- Reloading functionality is handled here.
			if binded and not self:_checkIfTrue(self._StateManagerClass:GetStatesBulk(self._Player)) then
			end
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then -- Shooting functionality is handled here.
			if binded and not self:_checkIfTrue(self._StateManagerClass:GetStatesBulk(self._Player), "Firing") then
				self._StateManagerClass:SetState(self._Player, "Firing", true) -- Plays the animation and lock's out other states.
				self._ViewmodelClass:PlayViewmodelAnimation(weaponData.Animations.Shooting, "Firing")

				local connection = self._ViewmodelClass.AnimationEnded:Once(function(animName)
					self._StateManagerClass:SetState(self._Player, animName, false) -- Once completed unlock other states/functions.
				end)
			end
		end

		if input.KeyCode == Enum.KeyCode.F then -- Inspection functionality is handled here.
			if binded and not self._StateManagerClass:GetStateData() then
				self._StateManagerClass:SetState(self._Player, "Inspecting", true)
				self._ViewmodelClass:PlayViewmodelAnimation(weaponData.Animations.Inspect, "Inspecting")

				local connection = self._ViewmodelClass.AnimationEnded:Once(
					function(animName) -- Once completed unlock other states/functions.
						self._StateManagerClass:SetState(self._Player, animName, false)
					end
				)

				self._maid:GiveTask(connection) -- Add's to the maid for cleanup at a later time.
			end
		end

		if input.KeyCode == Enum.KeyCode.V then -- Firing mode functionality is handled here.
			if binded and not self:_checkIfTrue(self._StateManagerClass:GetStatesBulk(self._Player)) then
				self._StateManagerClass:SetState(self._Player, "FireMode", true) -- Plays the animation and lock's out other states.
				self._ViewmodelClass:PlayViewmodelAnimation(weaponData.Animations.FireSelector, "FireMode")

				local connection = self._ViewmodelClass.AnimationEnded:Once(
					function(animName) -- Once completed unlock other states/functions.
						self._StateManagerClass:SetState(self._Player, animName, false)
					end
				)

				self._maid:GiveTask(connection) -- Add's to the maid for cleanup at a later time.
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		local number = nums[input.KeyCode]
	end)
end

--[[
	Used to figure out what keybind is which tool.

	@retuen ()
]]
function BaseCombatService:_SortTools(): {}
	local weaponData = game.ReplicatedStorage.ReadyOrNotRoblox.game.Shared.Modules.WeaponData
	local _Character = self._Player.Character or self._Player.CharacterAdded:Wait() -- Used to make sure the backpack is properly retrived not really used

	local count = 0

	for i, v in pairs(self._Player.Backpack:GetChildren()) do -- Get's the children of the backpack
		if v:IsA("Tool") then
			if v:HasTag("Weapon") then -- Checks if there tagged and a tool.
				if not weaponData:FindFirstChild(v.Name) then -- If we can't find there data throw and error.
					warn(
						string.format(
							"[BaseCombatService] - Cannot find module for tool with the name of %q.",
							tostring(v.Name)
						)
					)
				else
					local data = require(weaponData:FindFirstChild(v.Name))

					if data then -- If we found there data return it.
						print(string.format("[BaseCombatService] - Found weapon data %q", v.Name))
						self._Weapons[i] = data.ReturnData()
						count += 1
					else
						print(string.format("[BaseCombatService] - No weapon data found for %q", v.Name))
					end
				end
			end
		end
	end

	print(string.format("[BaseCombatService] - Successfully found %d weapon(s) with data.", count))
end

--[[
	Bulk check's if any variable in the state manager is true.

	@param states any -- The states you want to check.
	@param ... string -- The state you want to exclude.
	@return any
]]
function BaseCombatService:_checkIfTrue(states, ...): any
	local trueCount = 0

	for i, v in pairs(states) do
		if v == true and i ~= ... then
			trueCount += 1
		end
	end

	if trueCount > 0 then
		return true
	else
		return false
	end
end

function BaseCombatService:Destroy()
	self._maid:DoCleaning()
	print("[BaseCombatService] - Sucessfully destroyed BaseCombatService.")
end

return BaseCombatService
