local loader = require(script.Parent.Parent.loader)
local require = loader.load(script)

-- External Services
local UserInputService = game:GetService("UserInputService")

-- Internal Services
local BaseObject = require("BaseObject")
local Maid = require("Maid")
local Signal = require("Signal")

local BaseCombatInput = setmetatable({}, BaseObject)
BaseCombatInput.ClassName = "BaseCombatInput"
BaseCombatInput.__index = BaseCombatInput

function BaseCombatInput.new()
	local self = setmetatable(BaseObject.new(), BaseCombatInput)

	-- Services
	self._maid = Maid.new()

	-- Signals
	self.WeaponReloading = Signal.new()
	self.WeaponInspect = Signal.new()
	self.WeaponEquipped = Signal.new()
	self.WeaponFiremodeChanged = Signal.new()
	self.WeaponFired = Signal.new()
	self.WeaponFiredEnded = Signal.new()
	self.WeaponAim = Signal.new()

	self:InputLoop()

	return self
end

-- ========================
-- ====== Public API ======
-- ========================
--[[
    The main input loop that handles all input related logic.

    @return ()
]]
function BaseCombatInput:InputLoop(): ()
	local numbers = { -- Used to check keybinds.
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

	local connectionOne = UserInputService.InputBegan:Connect(function(Input: InputObject)
		if numbers[Input.KeyCode] then
			self.WeaponEquipped:Fire(numbers[Input.KeyCode])
		elseif Input.KeyCode == Enum.KeyCode.R then
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

function BaseCombatInput:Destory()
	self._maid:DoCleaning()
end

return BaseCombatInput
