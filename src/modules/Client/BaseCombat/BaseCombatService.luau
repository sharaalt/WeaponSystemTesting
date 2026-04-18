-- External Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
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
]]
function BaseCombatService:_mainLoop(): ()
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

	UserInputService.InputBegan:Connect(function(input: InputObject)
		local number = nums[input.KeyCode]

		if number then
			if self._Weapons[number] then
				local weaponData = self._Weapons[number]
				local camera = workspace.CurrentCamera

				self._ViewmodelClass:bindViewmodel(camera, weaponData.WeaponName)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		local number = nums[input.KeyCode]

		if number then
			if self._Weapons[number] then
				self._ViewmodelClass:unbindViewmodel()
			end
		end
	end)
end

function BaseCombatService:_SortTools(): {}
	local weaponData = game.ReplicatedStorage.ReadyOrNotRoblox.game.Shared.Modules.WeaponData
	local _Character = self._Player.Character or self._Player.CharacterAdded:Wait() -- Used to make sure the backpack is properly retrived not really used

	local count = 0

	for i, v in pairs(self._Player.Backpack:GetChildren()) do
		if v:IsA("Tool") then
			if v:HasTag("Weapon") then
				if not weaponData:FindFirstChild(v.Name) then
					warn(
						string.format(
							"[BaseCombatService] - Cannot find module for tool with the name of %q.",
							tostring(v.Name)
						)
					)
				else
					local data = require(weaponData:FindFirstChild(v.Name))

					if data then
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

function BaseCombatService:Destroy()
	self._maid:DoCleaning()
end

return BaseCombatService
