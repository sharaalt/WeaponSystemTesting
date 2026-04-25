-- External Requires
local RemoteEvents = game.ReplicatedStorage.Shared.RemoteEvents

-- External Services
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local MobileInputProfile = require(script.Parent.MobileInputProfile)

local loader = require(script.Parent.Parent.loader)
local require = loader.load(script)

-- Internal Services
local Maid = require("Maid")
local Signal = require("Signal")

local MobileInputService = {}
MobileInputService.ServiceName = "MobileInputService"

function MobileInputService:Init(serviceBag)
	assert(not self._serviceBag, "[AudioServiceClient] - AudioServiceClient already initalized.")

	self._serviceBag = assert(serviceBag, "[AudioServiceClient] - AudioServiceClient is already initalized!")

	-- Variables
	self._inputCache = {}
	self._player = Players.LocalPlayer

	-- Services
	self._maid = Maid.new()

	-- Signals
	self.InputUp = Signal.new()
	self.InputDown = Signal.new()
end

--[[
	Returns the users device type based on PrefferedInputType

	@param PrefferedInputType EnumItem -- The preferred input name
]]
function MobileInputService:_GetUserInputDevice(PrefferedInputType: EnumItem): string
	if typeof(PrefferedInputType) ~= "EnumItem" then -- If the inputType isnt a string thow a warning and return
		warn(
			string.format(
				"[MobileInputService] - Typeof PrefferedInputType %q is not a valid type.",
				tostring(typeof(PrefferedInputType))
			)
		)
		return
	end

	-- If it exists evaluate the type and return the device based on it
	if PrefferedInputType == Enum.PreferredInput.KeyboardAndMouse then
		return "Keyboard"
	elseif PrefferedInputType == Enum.PreferredInput.Touch then
		return "Touch"
	elseif PrefferedInputType == Enum.PreferredInput.Gamepad then
		return "Controller"
	end
end

--[[
	Binds an action to a specified KeyCode or UserInputType 

	@param ActionName string -- The name of the action you want to bind.
	@param func function -- The function you want to bind to the action.
	@param CreateGUI boolean -- Enables the creation of UI.
	@param InputType EnumItem -- The type of enumInput you want the button to pose as.
]]
function MobileInputService:BindAction(ActionName: string, func: any, CreateGUI: boolean, InputType: EnumItem): ()
	if typeof(ActionName) ~= "string" then
		warn(
			string.format(
				"[MobileInputService] - Type of ActionName %q is not a valid type.",
				tostring(typeof(ActionName))
			)
		)
		return
	end

	if typeof(func) ~= "function" then
		warn(string.format("[MobileInputService] - Type of func %q is not a valid type.", tostring(typeof(func))))
		return
	end

	if typeof(CreateGUI) ~= "boolean" then
		warn(
			string.format(
				"[MobileInputService] - Type of CreateGUI %q is not a valid type.",
				tostring(typeof(CreateGUI))
			)
		)
		return
	end

	if typeof(InputType) ~= "EnumItem" then
		warn(
			string.format(
				"[MobileInputService] - Type of InputType %q is not a valid type.",
				tostring(typeof(InputType))
			)
		)
		return
	end

	if self._inputCache[ActionName] then
		warn(
			string.format(
				"[MobileInputService] - Could not create a action bind as %q has been binded.",
				tostring(ActionName)
			)
		)
		return
	end

	for i, v in pairs(self._inputCache) do
		print(i, v)

		if v.InputEnum == InputType then
			warn(
				string.format(
					"[MobileInputService] - Could not create a action bind as InputType %q has been binded.",
					tostring(InputType)
				)
			)
			return nil
		end
	end

	local function UnbindFunc()
		if self._inputCache[ActionName] then
			ContextActionService:UnbindAction(ActionName)
			self._inputCache[ActionName] = nil
			print("[MobileInputService] - Unbinded input action.")
		end
	end

	local newId = 0
	for _ in pairs(self._inputCache) do
		newId += 1
	end

	local BindedTbl = MobileInputProfile.createBindTable(ActionName, newId, InputType, UnbindFunc)
	self._inputCache[ActionName] = BindedTbl

	ContextActionService:BindAction(ActionName, func, CreateGUI, InputType)

	return BindedTbl
end

-- --[[
-- 	Provides listeners for inputbegan and inputended functions.
-- ]]
-- function MobileInputService:SetupListeners(): ()
-- 	self._maid:DoCleaning() -- Remove old listeners

-- 	self._maid:GiveTask(UserInputService.InputBegan:Connect(function(inputObj: InputObject, gameProcessedEvent: boolean)
-- 		if not self._moveset then -- If not moveset is loaded throw a warning
-- 			warn("[InputService] - No active moveset stored.")
-- 			return
-- 		end

-- 		local deviceCategory = self:_GetUserInputDevice(UserInputService.PreferredInput)

-- 		if inputObj then
-- 			RemoteEvents.OnKeyDownInput:FireServer(deviceCategory, inputObj)
-- 		end

-- 		self._KeyDown:Fire(inputObj) -- Expose a signal for external use
-- 	end))

-- 	self._maid:GiveTask(UserInputService.InputEnded:Connect(function(inputObj: InputObject, gameProcessedEvent: boolean)
-- 		if not self._moveset then -- If not moveset is loaded throw a warning
-- 			warn("[InputService] - No active moveset stored.")
-- 			return
-- 		end

-- 		-- Gets the user device type and keybinds
-- 		local deviceCategory = self:_GetUserInputDevice(UserInputService.PreferredInput)

-- 		if inputObj then
-- 			RemoteEvents.OnKeyUpInput:FireServer(deviceCategory, inputObj)
-- 		end

-- 		self._KeyUp:Fire(inputObj) -- Expose a signal for external use
-- 	end))
-- end

-- function MobileInputService:Destroy()
-- 	self._maid:Destroy()
-- end

return MobileInputService
