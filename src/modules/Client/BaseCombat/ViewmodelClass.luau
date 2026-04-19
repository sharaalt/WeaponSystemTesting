local loader = require(script.Parent.Parent.loader)
local require = loader.load(script)

-- External Services
local RunService = game:GetService("RunService")

-- Internal Services
local BaseObject = require("BaseObject")
local Maid = require("Maid")
local Signal = require("Signal")

local ViewmodelClass = setmetatable({}, BaseObject)
ViewmodelClass.ClassName = "ViewmodelClass"
ViewmodelClass.__index = ViewmodelClass

function ViewmodelClass.new()
	local self = setmetatable(BaseObject.new(), ViewmodelClass)

	self._maid = Maid.new()

	-- Internal Variables
	self._viewmodelFunc = nil
	self._viewmodel = nil

	-- Signals
	self.AnimationPlayed = Signal.new()
	self.AnimationEnded = Signal.new()

	return self
end

-- ============================
-- ======== Public API ========
-- ============================

--[[
	Bind's a viewmodel to a specified object.

	@param object Instance -- The object you want to bind the viewmodel to.
	@param viewmodelName string -- The name of the viewmodel you want binded.
	@return ()
]]
function ViewmodelClass:BindViewmodel(object: Instance, viewmodelName: string): ()
	if self._viewmodel then -- If the viewmodel is already binded return.
		warn("[ViewmodelClass] - A viewmodel is already binded.")
		return
	end

	if typeof(object) ~= "Instance" then -- Check if the types match.
		warn(string.format("[ViewmodelClass] - Type of object %q is not a valid type.", tostring(typeof(object))))
		return
	end

	if typeof(viewmodelName) ~= "string" then
		warn(
			string.format(
				"[ViewmodelClass] - Type of viewmodelName %q is not a valid type.",
				tostring(typeof(viewmodelName))
			)
		)
		return
	end

	local pathToViewmodel: Model = game.ReplicatedStorage.Shared.Viewmodels[viewmodelName] -- Searches for the viewmodel

	if pathToViewmodel then -- If it exists continue.
		self._viewmodel = pathToViewmodel:Clone()
		self._viewmodel.Parent = workspace

		self._viewmodelFunc = RunService.RenderStepped:Connect(function(a0: number)
			self._viewmodel.PrimaryPart.CFrame = object.CFrame
		end)
	else -- If not throw a warning.
		warn(string.format("[ViewmodelClass] - No viewmodel exists with the name %q", tostring(viewmodelName)))
	end
end

function ViewmodelClass:PlayViewmodelAnimation(animId: string, animName: string, ...: boolean)
	if typeof(animId) ~= "string" then -- Some type checking.
		warn(string.format("[ViewmodelClass] - Typeof animId %q is not a valid type.", tostring(typeof(animId))))
		return
	end

	if animName and typeof(animName) ~= "string" then
		warn(string.format("[ViewmodelClass] - Typeof animName %q is not a valid type.", tostring(typeof(animName))))
		return
	end

	if not self:_isBinded() then
		warn("[ViewmodelClass] - No viewmodel is binded cannot play animation.")
		return
	end

	local viewmodelHum = self._viewmodel.Humanoid
	local animator: Animator = viewmodelHum.Animator -- Access the humanoid and animator.

	local newAnimation = Instance.new("Animation") -- Creates a new animation.
	newAnimation.AnimationId = animId

	local animTrack = animator:LoadAnimation(newAnimation) -- Creates a new track and play's it.
	animTrack.Looped = ... or false
	animTrack:Play()

	self.AnimationPlayed:Fire(animName)

	local connection = animTrack.Ended:Connect(function() -- Once completed fire the AnimationEnded signal.
		if animName ~= "" or nil then
			self.AnimationEnded:Fire(animName)
		end
	end)

	print("[ViewmodelClass] - Sucessfully played animation.")

	self._maid:GiveTask(newAnimation, animTrack, connection) -- Add's to the maid for cleanup later.

	if ... then
		return animTrack -- Hands off to BaseCombatService for handling.
	end
end

--[[
	Unbinds the viewmodel from the object.

	@return ()
]]
function ViewmodelClass:UnbindViewmodel(): ()
	if not self._viewmodel or not self._viewmodelFunc then
		warn("[ViewmodelClass] - No viewmodel object or function exists.")
		return
	end

	self._viewmodelFunc:Disconnect() -- Destroys and cleans up the model/func
	self._viewmodelFunc = nil
	self._viewmodel:Destroy()
	self._viewmodel = nil
end

--[[
	Aim's down sights instead of regularly holding the weapon.

	@return ()
]]
function ViewmodelClass:AimdownWeapon(): () end

-- ========================
-- ====== Private API =====
-- ========================
--[[
	Returns the viewmodel object for other purposes.

	@return Model
]]
function ViewmodelClass:_returnViewmodel(): Model
	if self._viewmodel then
		return self._viewmodel
	else
		warn("[ViewmodelClass] - Viewmodel is not binded or does not exist.")
		return nil
	end
end

--[[
	Unbinds the viewmodel function only.

	@return ()
]]
function ViewmodelClass:_unbindFunction(): ()
	if not self._viewmodelFunc then
		warn("[ViewmodelClass] - No viewmodel function exists.")
		return
	end

	self._viewmodelFunc:Disconnect() -- Destroys and cleans up the model/func
	self._viewmodelFunc = nil
end

--[[
	Unbinds the viewmodel only.

	@return ()
]]
function ViewmodelClass:_unbindModel(): ()
	if not self._viewmodel then
		warn("[ViewmodelClass] - No viewmodel function exists.")
		return
	end

	self._viewmodel:Destroy()
	self._viewmodel = nil
end

--[[
	Returns whether the model is binded or not.

	@return boolean	
]]
function ViewmodelClass:_isBinded(): ()
	if self._viewmodel then
		return true
	else
		return false
	end
end

function ViewmodelClass:Destroy()
	self._maid:DoCleaning()
	print("[ViewmodelClass] - Sucessfully destroyed ViewmodelClass.")
end

return ViewmodelClass
