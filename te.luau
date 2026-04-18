-- External Services
local RemoteEvents = game.ReplicatedStorage.Shared.RemoteEvents

-- Defenitions
local require: any = (require(script.Parent:WaitForChild("loader")) :: any).load(script)

-- Internal Services
local BaseObject = require("BaseObject")
local Maid = require("Maid")
local Rx = require("Rx")
local Signal = require("Signal")

-- External Services
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local BaseCombatClass = setmetatable({}, BaseObject)
BaseCombatClass.ClassName = "BaseCombatClass"
BaseCombatClass.__index = BaseCombatClass

function BaseCombatClass.new(player)
	assert(player, "[BaseCombatClass] - Player cannot be nil or false.")

	print("[BaseCombatClass] - Creating BaseCombatClass...")

	local self = setmetatable(BaseObject.new(), BaseCombatClass)

	-- Dynamic Values
	self._Weapons = {}
	self._WeaponValues = nil

	-- Static Values
	self._Player = player

	-- Services
	self._Maid = Maid.new()

	self._Maid:GiveTask(task.spawn(function()
		self:_SortTools()
		self:MainLoop()
	end))

	return self
end

function BaseCombatClass:RemoteEvents()
	Rx.fromSignal(RemoteEvents.OnWeaponLoadRequest.OnClientEvent)
		:Pipe({
			Rx.map(function(WeaponName)
				return WeaponName
			end),
		})
		:Subscribe(function(WeaponName)
			self:LoadWeapon(WeaponName)
		end)
end

function BaseCombatClass:MainLoop()
	local viewmodelFunc = nil
	local newModel: Model = nil
	local nums = {
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
	local stateData = {
		Equipped = false,
		Equipping = false,
		UnEqupping = false,
		Reloading = false,
		Shooting = false,
		Inspecting = false,
		AmmoInspect = false,
		Aiming = false,
		FireMode = 0, -- 0 Semi, 1 Auto
		MaxAmmo = 0,
		Ammo = 0,
	}
	local animations = {
		Idle = nil,
	}

	local currentData = nil
	local holdingR = nil
	local holdingMB1 = nil

	--== Phase 1. Collecting Input ==--
	--== Input is collected here and processed ==--
	--== Notes: Might be better to handle it somewhere else? ==--
	UIS.InputBegan:Connect(function(a0: InputObject, a1: boolean)
		local number = nums[a0.KeyCode]

		if number ~= nil then
			if stateData.Equipped == true then
				stateData.UnEqupping = true
				stateData.Equipped = false

				local anim: AnimationTrack =
					self:_PlayAnimation(newModel.Humanoid.Animator, currentData.Animations.UnEquip)
				anim:GetMarkerReachedSignal("DestroyModel"):Connect(function()
					newModel:Destroy()
					newModel = nil
					viewmodelFunc:Disconnect()
					viewmodelFunc = nil
					currentData = nil
					stateData = {
						Equipped = false,
						Equipping = false,
						UnEqupping = false,
						Reloading = false,
						Shooting = false,
						Inspecting = false,
						AmmoInspect = false,
						Aiming = false,
						FireMode = 0,
						MaxAmmo = 0,
						Ammo = 0,
					}
				end)
				return
			end

			if self._Weapons[number] then
				local data = self._Weapons[number]

				if currentData then
					if currentData.WeaponName == data.WeaponName then
						return
					end
				else
					currentData = data
					stateData.Equipped = true
					stateData.MaxAmmo = currentData.MaxAmmo
					stateData.Ammo = stateData.MaxAmmo
					print(stateData.Equipped)
					print("[BaseCombatClass] - Weapon data found.")
					return
				end
			else
				print("[BaseCombatClass] - No data match found.")
			end
		end

		if a0.UserInputType == Enum.UserInputType.MouseButton1 then -- Use for firing/shooting
			if self:_IsStateInProgress(stateData) or stateData.Equipped == false then
				return
			end

			self:_IdleAnimHelper(animations, true, nil, nil)

			holdingMB1 = true

			if stateData.Ammo <= 0 then
				return
			end

			if stateData.FireMode == 0 then
				stateData.Ammo -= 1
				print(stateData.Ammo)
				self:_PlayAnimation(newModel.Humanoid.Animator, currentData.Animations.Shooting)
				return
			elseif stateData.FireMode == 1 then
				while holdingMB1 do
					task.wait(0.2)
					if stateData.Ammo <= 0 then
						return
					end

					self:_PlayAnimation(newModel.Humanoid.Animator, currentData.Animations.Shooting)

					stateData.Ammo -= 1
					print(stateData.Ammo)
				end
			end
		end

		if a0.KeyCode == Enum.KeyCode.R then -- Used for reloading and inspecting ammo
			if self:_IsStateInProgress(stateData) or stateData.Equipped == false then
				return
			end

			holdingR = true

			self:_IdleAnimHelper(animations, true, nil, nil)

			task.delay(0.5, function()
				if holdingR then
					stateData.AmmoInspect = true
					local anim = self:_PlayAnimation(newModel.Humanoid.Animator, currentData.Animations.CheckingAmmo)
					newModel[currentData.WeaponName].Mag.UIPart.SurfaceGui.AmmoText.Text = stateData.Ammo
					anim:GetMarkerReachedSignal("PauseEvent"):Connect(function()
						animations["CheckingAmmo"] = anim
						anim:AdjustSpeed(0)
					end)
				else
					stateData.Reloading = true
					local anim = self:_PlayAnimation(newModel.Humanoid.Animator, currentData.Animations.ReloadWithAmmo)
					anim.Ended:Connect(function()
						stateData.Ammo = stateData.MaxAmmo
						stateData.Reloading = false
						self:_IdleAnimHelper(animations, false, newModel.Humanoid.Animator, currentData.Animations.Idle)
					end)
				end
			end)
		end

		if a0.KeyCode == Enum.KeyCode.F then -- Used for inspecting the weapon
			if self:_IsStateInProgress(stateData) or stateData.Equipped == false then
				return
			end

			self:_IdleAnimHelper(animations, true, nil, nil)

			stateData.Inspecting = true
			local anim = self:_PlayAnimation(newModel.Humanoid.Animator, currentData.Animations.Inspect)
			anim.Ended:Connect(function()
				stateData.Inspecting = false
				self:_IdleAnimHelper(animations, false, newModel.Humanoid.Animator, currentData.Animations.Idle)
			end)
		end

		if a0.KeyCode == Enum.KeyCode.V then -- Switchs between firing modes
			if self:_IsStateInProgress(stateData) or stateData.Equipped == false then
				return
			end

			self:_IdleAnimHelper(animations, true, nil, nil)

			stateData.Inspecting = true
			local anim = self:_PlayAnimation(newModel.Humanoid.Animator, currentData.Animations.FireSelector)
			anim.Ended:Connect(function()
				stateData.Inspecting = false
				if stateData.FireMode == 0 then
					stateData.FireMode = 1
				else
					stateData.FireMode = 0
				end

				self:_IdleAnimHelper(animations, false, newModel.Humanoid.Animator, currentData.Animations.Idle)
			end)
		end
	end)

	UIS.InputEnded:Connect(function(a0: InputObject, a1: boolean)
		if a0.UserInputType == Enum.UserInputType.MouseButton1 then
			if stateData.Equipped == false then
				return
			end

			holdingMB1 = false
			self:_IdleAnimHelper(animations, false, newModel.Humanoid.Animator, currentData.Animations.Idle)
		end

		if a0.KeyCode == Enum.KeyCode.R then
			if currentData == nil then
				return
			end

			if animations.CheckingAmmo then
				holdingR = false
				animations.CheckingAmmo:AdjustSpeed(1)

				animations.CheckingAmmo.Ended:Connect(function()
					stateData.AmmoInspect = false
					self:_IdleAnimHelper(animations, false, newModel.Humanoid.Animator, currentData.Animations.Idle)
					animations.CheckingAmmo:Destroy()
					animations.CheckingAmmo = nil
				end)
			else
				holdingR = false
			end
		end
	end)

	--== Phase 2. Weapon System ==--
	--== Once a weapon is a equipped it is processed through here the weapon area ==--
	--== Notes: Come up with a better name... ==--
	RunService.Heartbeat:Connect(function()
		if stateData.Equipped and stateData.UnEqupping == false then
			if viewmodelFunc == nil then
				newModel = currentData.ViewmodelPath:Clone()

				newModel.Parent = workspace
				stateData.Equipping = true
				local anim = self:_PlayAnimation(newModel.Humanoid.Animator, currentData.Animations.Equip)
				anim.Ended:Connect(function()
					local anim2: AnimationTrack =
						self:_PlayAnimation(newModel.Humanoid.Animator, currentData.Animations.Idle, true)
					stateData.Equipping = false
					animations.Idle = anim2
				end)

				viewmodelFunc = RunService.RenderStepped:Connect(function() -- The stupidest thing I've ever done XD
					if newModel == nil then
						return
					end

					newModel.PrimaryPart.CFrame = game.Workspace.CurrentCamera.CFrame
				end)
			end
		else
			if stateData.Equipped == true then
				return
			end
		end
	end)
end

function BaseCombatClass:_SortTools()
	local weaponData = game.ReplicatedStorage.ReadyOrNotRoblox.game.Shared.Modules.WeaponData
	local _Character = self._Player.Character or self._Player.CharacterAdded:Wait() -- Used to make sure the backpack is properly retrived not really used

	for i, v in pairs(self._Player.Backpack:GetChildren()) do
		if v:IsA("Tool") then
			if v:HasTag("Weapon") then
				local data = require(weaponData:FindFirstChild(v.Name))

				if data then
					print(string.format("[BaseCombatClass] - Found weapon data %q", v.Name))
					self._Weapons[i] = data.ReturnData()
					print(self._Weapons)
				else
					print(string.format("[BaseWeaponClass] - No weapon data found for %q", v.Name))
				end
			end
		end
	end
end

function BaseCombatClass:_PlayAnimation(animator: Animator, ID: string, ...)
	if ID == nil or animator == nil then
		warn("[BaseWeaponClass] - Animator or Animation ID is nil.")
	end
	local varArg = ...
	local animation: Animation = Instance.new("Animation")
	animation.AnimationId = ID

	local track: AnimationTrack = animator:LoadAnimation(animation)
	track.Looped = varArg

	track:Play()

	self._Maid:GiveTask(animation, track)
	return track
end

function BaseCombatClass:_IsStateInProgress(stateData, key)
	for i, v in pairs(stateData) do
		print(i, v)
		if v == true and i ~= key and i ~= "Equipped" then
			return true
		end
	end
end

function BaseCombatClass:_IdleAnimHelper(animations, bool, animator, str)
	if bool then
		print(animations.Idle)
		animations.Idle:Stop()
		animations.Idle:Destroy()
		animations.Idle = nil
		print(animations.Idle)
	else
		animations.Idle = self:_PlayAnimation(animator, str, true)
	end
end

function BaseCombatClass:Destroy()
	self._Maid:DoCleaning()
	print("[BaseCombatClass] - BaseCombatClass cleaned and destroyed.")
end

return BaseCombatClass
