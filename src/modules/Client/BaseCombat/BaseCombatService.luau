-- External Services
local Types = require(script.Parent.Types)
local Players = game:GetService("Players")
local RemoteEvents = game.ReplicatedStorage.Shared.RemoteEvents
local BaseCombatConstants = require(script.Parent.Parent.Parent.Shared.BaseCombatConstanants)
local BaseCombatInput = require(script.Parent.BaseCombatInput)
local BaseCombatProfile = require(script.Parent.BaseCombatProfile)
local StateManagerClass = require(script.Parent.Parent.StateManager.StateManagerClass)
local ViewmodelClass = require(script.Parent.ViewmodelClass)

local loader = require(script.Parent.Parent.loader)
local require = loader.load(script)

-- Internal Services
local Maid = require("Maid")

local BaseCombatService = {}
BaseCombatService.ServiceName = "BaseCombatService"

function BaseCombatService:Init(serviceBag)
	assert(not self._serviceBag, "[BaseCombatService] - BaseCombatService is already initalized!")
	self._serviceBag = assert(serviceBag, "[BaseCombatService] - BaseCombatService is already initalized!")

	-- Variables
	self._Weapons = {}
	self._Player = Players.LocalPlayer

	-- Services
	self._maid = Maid.new()
	self._ViewmodelClass = ViewmodelClass.new()
	self._StateManagerClass = StateManagerClass.new()
	self._BaseCombatInput = BaseCombatInput.new()
	self._AudioServiceClient = self._serviceBag:GetService(require("AudioServiceClient"))

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
	local weaponData: Types.WeaponData = nil

	self._maid:GiveTask(self._BaseCombatInput.WeaponReloading:Connect(function()
		local binded = self._ViewmodelClass:_isBinded()

		if binded and not self:_checkIfTrue(self._StateManagerClass:GetStatesBulk(self._Player)) then
			local ammo = weaponData.WeaponData.Ammo
			local idleAnimation: AnimationTrack = self._StateManagerClass:GetStateData(self._Player, "IdleAnimation")

			if ammo == weaponData.WeaponData.MaxAmmo then
				warn("[BaseCombatService] - Magazine is already full no need to reload!")
				return
			end

			idleAnimation:Stop()

			if ammo > 0 then
				self._StateManagerClass:SetState(self._Player, "Reloading", true) -- Plays the animation and lock's out other states.
				self._ViewmodelClass:PlayViewmodelAnimation(weaponData.Animations.ReloadWithAmmo, "Reloading")
				self._AudioServiceClient:PlayAudio("ReloadSound", false)

				local connection = self._ViewmodelClass.AnimationEnded:Once(function(animName)
					self._StateManagerClass:SetState(self._Player, animName, false) -- Once completed unlock other states/functions.
					weaponData.WeaponData.Ammo = weaponData.WeaponData.MaxAmmo
					idleAnimation:Play()
				end)

				self._maid:GiveTask(connection) -- Add's to the maid for cleanup at a later time.
			else
				self._StateManagerClass:SetState(self._Player, "Reloading", true) -- Plays the animation and lock's out other states.
				self._ViewmodelClass:PlayViewmodelAnimation(weaponData.Animations.ReloadWithNoAmmo, "Reloading")
				self._AudioServiceClient:PlayAudio("ReloadSound", false)

				local connection = self._ViewmodelClass.AnimationEnded:Once(function(animName)
					self._StateManagerClass:SetState(self._Player, animName, false) -- Once completed unlock other states/functions.
					weaponData.WeaponData.Ammo = weaponData.WeaponData.MaxAmmo
					idleAnimation:Play()
				end)

				self._maid:GiveTask(connection) -- Add's to the maid for cleanup at a later time.
			end
		end
	end))

	self._maid:GiveTask(self._BaseCombatInput.WeaponInspect:Connect(function()
		local binded = self._ViewmodelClass:_isBinded()

		if binded and not self:_checkIfTrue(self._StateManagerClass:GetStatesBulk(self._Player)) then
			local idleAnimation: AnimationTrack = self._StateManagerClass:GetStateData(self._Player, "IdleAnimation")

			idleAnimation:Stop()

			print(self._Player)
			self._StateManagerClass:SetState(self._Player, "Inspecting", true)

			self._ViewmodelClass:PlayViewmodelAnimation(weaponData.Animations.Inspect, "Inspecting")
			self._AudioServiceClient:PlayAudio("InspectSound", false)

			local connection = self._ViewmodelClass.AnimationEnded:Once(
				function(animName) -- Once completed unlock other states/functions.
					self._StateManagerClass:SetState(self._Player, animName, false)
					idleAnimation:Play()
				end
			)

			self._maid:GiveTask(connection) -- Add's to the maid for cleanup at a later time.
		end
	end))

	self._maid:GiveTask(self._BaseCombatInput.WeaponEquipped:Connect(function(number)
		local binded = self._ViewmodelClass:_isBinded()

		if self._Weapons[number] then -- Checks if that number is cached in the weapons table.
			local camera = workspace.CurrentCamera

			if binded then -- If the viewmodel is binded unbind it.
				if self:_checkIfTrue(self._StateManagerClass:GetStatesBulk(self._Player)) then
					warn("[BaseCombatClass] - A state is true you cannot unequip at this time.")
					return
				end

				self._ViewmodelClass:PlayViewmodelAnimation(weaponData.Animations.UnEquip, "UnEquipping")

				self._StateManagerClass:SetState(self._Player, "UnEquipping", true)
				self._AudioServiceClient:PlayAudio("UnequipSound", false)

				local connection = self._ViewmodelClass.AnimationEnded:Once(function(animName)
					self._StateManagerClass:SetState(self._Player, animName, false)
					self._StateManagerClass:RemoteStateTable(self._Player)
					self._ViewmodelClass:UnbindViewmodel()
					weaponData = nil
				end)

				self._maid:GiveTask(connection)
			else -- If it's not binded bind it.
				self._StateManagerClass:CreateStateTable(BaseCombatConstants.GetStates(), self._Player) -- Initalize the state table

				if self:_checkIfTrue(self._StateManagerClass:GetStatesBulk(self._Player)) then -- Lock's out unequipping/other functions.
					warn("[BaseCombatClass] - A state is true you cannot equip at this time.")
					return
				end

				weaponData = self._Weapons[number]
				self._StateManagerClass:SetState(self._Player, "Equipping", true) -- Unlocks unequipping/other functions.
				self._ViewmodelClass:BindViewmodel(camera, weaponData.WeaponName)
				self._ViewmodelClass:PlayViewmodelAnimation(weaponData.Animations.Equip, "Equipping")

				self._AudioServiceClient:PlayAudio("EquipSound", false)

				local connection = self._ViewmodelClass.AnimationEnded:Once(function(animName)
					self._StateManagerClass:SetState(self._Player, animName, false)
					local Animation = self._ViewmodelClass:PlayViewmodelAnimation(weaponData.Animations.Idle, "", true)
					self._StateManagerClass:SetState(self._Player, "IdleAnimation", Animation)
				end)

				self._maid:GiveTask(connection)
			end
		else
			warn(
				string.format(
					"[BaseCombatService] - Cannot find any weapon with in the backpack with number %i",
					number
				)
			)
			return
		end
	end))

	self._maid:GiveTask(self._BaseCombatInput.WeaponFiremodeChanged:Connect(function()
		local binded = self._ViewmodelClass:_isBinded()

		if binded and not self:_checkIfTrue(self._StateManagerClass:GetStatesBulk(self._Player)) then
			local idleAnimation: AnimationTrack = self._StateManagerClass:GetStateData(self._Player, "IdleAnimation")

			idleAnimation:Stop()

			self._StateManagerClass:SetState(self._Player, "FireMode", true) -- Plays the animation and lock's out other states.
			self._ViewmodelClass:PlayViewmodelAnimation(weaponData.Animations.FireSelector, "FireMode")

			self._AudioServiceClient:PlayAudio("FireSelectorSound", false)

			local connection = self._ViewmodelClass.AnimationEnded:Once(
				function(animName) -- Once completed unlock other states/functions.
					self._StateManagerClass:SetState(self._Player, animName, false)
					if weaponData.WeaponData.FireMode == 1 then
						weaponData.WeaponData.FireMode = 2
					else
						weaponData.WeaponData.FireMode = 1
					end

					idleAnimation:Play()
				end
			)

			self._maid:GiveTask(connection) -- Add's to the maid for cleanup at a later time.
		end
	end))

	self._maid:GiveTask(self._BaseCombatInput.WeaponFired:Connect(function()
		local binded = self._ViewmodelClass:_isBinded()

		if not binded then
			return
		end

		local idleAnimation: AnimationTrack = self._StateManagerClass:GetStateData(self._Player, "IdleAnimation")
		local fireMode = weaponData.WeaponData.FireMode

		if fireMode == 1 then
			if binded and not self:_checkIfTrue(self._StateManagerClass:GetStatesBulk(self._Player)) then
				local ammo = weaponData.WeaponData.Ammo

				if ammo <= 0 then
					warn("[BaseCombatService] - Cannot shoot on an empty magazine.")
					return
				end

				idleAnimation:Stop()

				local viewmodelObject: Model = self._ViewmodelClass:_returnViewmodel()
				local attachment: Attachment = viewmodelObject[weaponData.WeaponName].Barrel.Attachment
				local origin: Attachment = attachment.WorldPosition

				weaponData.WeaponData.Ammo = math.clamp(ammo - 1, 0, weaponData.WeaponData.MaxAmmo)

				self._AudioServiceClient:PlayAudio("FireSound", false)

				self._StateManagerClass:SetState(self._Player, "Firing", true) -- Plays the animation and lock's out other states.
				self._ViewmodelClass:PlayViewmodelAnimation(weaponData.Animations.Shooting, "Firing")
				RemoteEvents.OnWeaponFireRequest:FireServer(weaponData.WeaponData, origin, self:_GetMousePos())

				local connection = self._ViewmodelClass.AnimationEnded:Once(function(animName)
					self._StateManagerClass:SetState(self._Player, animName, false) -- Once completed unlock other states/functions.
					idleAnimation:Play()
				end)

				self._maid:GiveTask(connection) -- Add's to the maid for cleanup at a later time.

				return
			end
		end

		if fireMode == 2 then
			if binded and not self:_checkIfTrue(self._StateManagerClass:GetStatesBulk(self._Player, "Firing")) then
				self._StateManagerClass:SetState(self._Player, "HoldingMb1", true)

				idleAnimation:Stop()

				local loopFunc = task.spawn(function()
					while true do
						task.wait(weaponData.WeaponData.FireRate)
						local ammo = weaponData.WeaponData.Ammo

						if ammo <= 0 then -- Simple ammo check.
							warn("[BaseCombatService] - Cannot shoot on an empty magazine.")
							return
						end

						if self._StateManagerClass:GetStateData(self._Player, "HoldingMb1") == false then -- Break's off the loop if we are not holding MB1
							break
						end

						local viewmodelObject: Model = self._ViewmodelClass:_returnViewmodel()
						local attachment: Attachment = viewmodelObject[weaponData.WeaponName].Barrel.Attachment
						local origin: Attachment = attachment.WorldPosition

						weaponData.WeaponData.Ammo = math.clamp(ammo - 1, 0, weaponData.WeaponData.MaxAmmo) -- Updates the weapons ammo.

						self._AudioServiceClient:PlayAudio("FireSound", false)

						self._StateManagerClass:SetState(self._Player, "Firing", true) -- Plays the animation and lock's out other states.
						RemoteEvents.OnWeaponFireRequest:FireServer(weaponData.WeaponData, origin, self:_GetMousePos())

						self._ViewmodelClass:PlayViewmodelAnimation(weaponData.Animations.Shooting, "Firing")

						local connection = self._ViewmodelClass.AnimationEnded:Once(function(animName)
							self._StateManagerClass:SetState(self._Player, animName, false) -- Once completed unlock other states/functions.
							idleAnimation:Play()
						end)

						self._maid:GiveTask(connection) -- Add's to the maid for cleanup at a later time.
					end
				end)

				self._maid:GiveTask(loopFunc)
			end
		end
	end))

	self._maid:GiveTask(self._BaseCombatInput.WeaponFiredEnded:Connect(function()
		local binded = self._ViewmodelClass:_isBinded()

		if weaponData and self._StateManagerClass:GetStateData(self._Player, "HoldingMb1") then
			self._StateManagerClass:SetState(self._Player, "HoldingMb1", false)
		end
	end))

	self._maid:GiveTask(self._BaseCombatInput.WeaponAim:Connect(function()
		local binded = self._ViewmodelClass:_isBinded()

		if binded and not self:_checkIfTrue(self._StateManagerClass:GetStatesBulk(self._Player)) then
			self._ViewmodelClass:AimdownWeapon("M4A1")
		end
	end))
end

--[[
	Get's the player's mouse position.

	@retuen Vector3
]]
function BaseCombatService:_GetMousePos(): Vector3
	local Mouse: Mouse = self._Player:GetMouse()

	return Mouse.Hit.Position
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
						self._Weapons[i] = BaseCombatProfile.CreateWeaponDataTable(data.ReturnData())
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
