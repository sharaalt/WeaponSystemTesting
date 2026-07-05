--[[
    @author sharafzada 
    @class BaseCombatInput.luau
    @version 1.0.0

    Handles all the combat related input and fire's signals for each event that occurs.
]]

-- External Services
local UserInputService = game:GetService("UserInputService")

local loader = require(script.Parent.Parent.loader)
local require = loader.load(script)

-- Internal Services
local BaseObject = require("BaseObject")
local Maid = require("Maid")
local Signal = require("Signal")

local BaseCombatInput = setmetatable({}, BaseObject)
BaseCombatInput.ServiceName = "BaseCombatInput"
BaseCombatInput.__index = BaseCombatInput

function BaseCombatInput.new()
	local self = setmetatable(BaseObject.new(), BaseCombatInput)

	-- Services
	self._maid = Maid.new()

	-- Signals
	self.WeaponEquipped = Signal.new()
	self.WeaponReloading = Signal.new()
	self.WeaponEquipping = Signal.new()
	self.WeaponUnequipping = Signal.new()

	self._maid:GiveTask(task.spawn(function()
		self:_InputLoop()
	end))

	return self
end

-- =======================
-- ===== Private API =====
-- =======================
--[[
    Wraps the UserInputService inside of the class.

    @return ()
]]
function BaseCombatInput:_InputLoop()
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

	-- Input Began functions
	local ConnectionOne = UserInputService.InputBegan:Connect(function(input: InputObject)
		if numbers[input.KeyCode] then
			self.WeaponEquipped:Fire(numbers[input.KeyCode])
		elseif input.KeyCode == Enum.KeyCode.R then
			self.WeaponReloading:Fire()
		elseif input.KeyCode == Enum.KeyCode.F then
			print("Changing Firing Mode")
		end
	end)

	-- Input Ended functions
	local ConnectionTwo = UserInputService.InputEnded:Connect(function(input: InputObject)
		if numbers[input.KeyCode] then
			self.WeaponUnequipping:Fire(numbers[input.KeyCode])
		end
	end)

	-- Hand functions off for maid cleanup.
	self._maid:GiveTask(ConnectionOne, ConnectionTwo)
end

function BaseCombatInput:Destroy()
	self._maid:DoCleaning()
	print("[BaseCombatInput] - Sucessfully destroyed BaseCombatInput.")
end

return BaseCombatInput
