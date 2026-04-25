local loader = require(script.Parent.Parent.loader)
local require = loader.load(script)

-- External Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Internal Services
local BaseObject = require("BaseObject")
local Maid = require("Maid")
local Signal = require("Signal")

local BaseCombatInput = setmetatable({}, BaseObject)
BaseCombatInput.ClassName = "BaseCombatInput"
BaseCombatInput.__index = BaseCombatInput

function BaseCombatInput.new(MobileInputService)
	local self = setmetatable(BaseObject.new(), BaseCombatInput)

	-- Variables
	self._player = Players.LocalPlayer
	self._numbers = { -- Used to check keybinds.
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

	-- Services
	self._maid = Maid.new()
	self._MobileInputService = MobileInputService

	-- Signals
	self.WeaponReloading = Signal.new()
	self.WeaponInspect = Signal.new()
	self.WeaponEquipped = Signal.new()
	self.WeaponFiremodeChanged = Signal.new()
	self.WeaponFired = Signal.new()
	self.WeaponFiredEnded = Signal.new()
	self.WeaponAim = Signal.new()

	self._maid:GiveTask(task.spawn(function()
		self:_BindMobileInput()
		self:InputLoop()
	end))

	return self
end

-- ========================
-- ====== Public API ======
-- ========================

--[[
	Manually triggers the equip function for mobile users.

	@return number
]]
function BaseCombatInput:TranslateEquipInput(input: number | Enum.KeyCode): number
	if typeof(input) == "number" then
		self.WeaponEquipped:Fire(input)
	elseif typeof(input) == "EnumItem" then
		local slot = self._numbers[input]

		if slot then
			self.WeaponEquipped:Fire(slot)
		end
	end
end

--[[
    The main input loop that handles all input related logic.

    @return ()
]]
function BaseCombatInput:InputLoop(): ()
	local connectionOne = UserInputService.InputBegan:Connect(function(Input: InputObject)
		if self._numbers[Input.KeyCode] then -- Make sure the number is a valid keycode before processing.
			self:TranslateEquipInput(Input.KeyCode) -- Translate the input for mobile support.
		elseif Input.KeyCode == Enum.KeyCode.R then
			print("a")
			self.WeaponReloading:Fire()
		elseif Input.KeyCode == Enum.KeyCode.F then
			self.WeaponInspect:Fire()
		elseif Input.KeyCode == Enum.KeyCode.V then
			self.WeaponFiremodeChanged:Fire()
		elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.WeaponFired:Fire()
		elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
			self.WeaponAim:Fire()
		end
	end)

	local connectionTwo = UserInputService.InputEnded:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.WeaponFiredEnded:Fire()
		end
	end)

	self._maid:GiveTask(connectionOne, connectionTwo)
end

-- =========================
-- ====== Private API ======
-- =========================
--[[
	Binds input to mobile devices.

	@return ()
]]
function BaseCombatInput:_BindMobileInput(): ()
	local function reloadFunc()
		self.WeaponReloading:Fire()
	end

	local function inspectFunc()
		self.WeaponInspect:Fire()
	end

	local function firemodeChange()
		self.WeaponFiremodeChanged:Fire()
	end

	local function weaponFired(actionName, inputState, inputObject)
		self.WeaponFired:Fire()
	end

	local function weaponAim(actionName, inputState, inputObject)
		if inputState == Enum.UserInputState.Begin then
			self.WeaponAim:Fire()
		end
	end

	local reloadBind = self._MobileInputService:BindAction("ReloadWeapon", reloadFunc, true, Enum.KeyCode.R)
	reloadBind:SetPosition(UDim2.new(1, -83, 1, -140))
	local inpsectBind = self._MobileInputService:BindAction("WeaponInspect", inspectFunc, true, Enum.KeyCode.F)
	inpsectBind:SetPosition(UDim2.new(1, -145, 1, -78))
	self._MobileInputService:BindAction("WeaponFiremodeChanged", firemodeChange, true, Enum.KeyCode.V)
	self._MobileInputService:BindAction("WeaponFired", weaponFired, true, Enum.KeyCode.C)
	self._MobileInputService:BindAction("WeaponAim", weaponAim, true, Enum.KeyCode.A)
end

function BaseCombatInput:Destory()
	self._maid:DoCleaning()
end

return BaseCombatInput
