--[[
    @author sharafzada
    @class ViewmodelHelper.luau
    @version 1.0.0

	-- To-Do list
	@todo Also a lot :p

    To prevent over bloating BaseCombatService & to maintain readability ViewmodelHelper.luau is used to provide helper functions for viewmodel related tasks
    i.e. Playing animations, Viewmodel Lifecycle, etc.
]]

-- External Requierments
local RunService = game:GetService("RunService")

local Viewmodels = game.ReplicatedStorage.Shared.Viewmodels
local BaseCombatProfile = require(script.Parent.BaseCombatProfile)
local Types = require(script.Parent.Types)

local loader = require(script.Parent.Parent.loader)
local require = loader.load(script)

-- Internal Services
local BaseObject = require("BaseObject")
local Maid = require("Maid")
local Signal = require("Signal")

local ViewmodelHelper = setmetatable({}, BaseObject)
ViewmodelHelper.ServiceName = "ViewmodelHelper"
ViewmodelHelper.__index = ViewmodelHelper

function ViewmodelHelper.new(player)
	local self = setmetatable(BaseObject.new(), ViewmodelHelper)

	-- Variables
	self._ActiveViewmodel = nil
	self._Player = player

	-- Services
	self._maid = Maid.new()

	-- Signals
	self.ViewmodelLoaded = Signal.new()
	self.ViewmodelDestroyed = Signal.new()
	self.AnimationCompleted = Signal.new()

	return self
end

-- ==================
-- === Public API ===
-- ==================
--[[
    Attachs a viewmodel to the player linked to the class.

    @param viewmodelname string -- The name of the viewmodel you want to attach.
    
    @return ()
]]
function ViewmodelHelper:AttachViewmodel(viewmodelname: string): ()
	-- Although not really needed always nice to have type checking.
	if typeof(viewmodelname) ~= "string" then
		warn(string.format("[ViewmodelHelper] - Type of viewmodelname %q is not a valid type.", typeof(viewmodelname)))
		return
	end

	if self._ActiveViewmodel then
		warn("[ViewmodelHelper] - Cannot attach a viewmodel whilst one is active.")
		return
	end

	-- Retrive's the viewmodel from replicated storage.
	local viewmodel: Model = Viewmodels:WaitForChild(viewmodelname, 5)

	-- Check's if it's not nil
	if viewmodel then
		-- Setup the viewmodel and connection.
		local newViewmodel: Model = viewmodel:Clone()
		newViewmodel.Parent = workspace

		local connection = RunService.RenderStepped:Connect(function()
			newViewmodel.PrimaryPart:PivotTo(workspace.CurrentCamera.CFrame)
		end)

		-- Format it into a table and set the activeViewmodel.
		local ViewmodelData: Types.ViewmodelData = BaseCombatProfile.FormatViewmodelTable(newViewmodel, connection)
		self._ActiveViewmodel = ViewmodelData

		-- Hand off connection for maid cleanup.
		self._maid:GiveTask(connection)

		-- A bit of confirmation when debugging.
		print(string.format("[ViewmodelHelper] - Sucessfully binded %q to the user.", newViewmodel.Name))
	end
end

--[[
	Play's a designated animation for the viewmodel (ideally should be viewmodel related if that wasn't obvious enough).

	@param animationId string -- The ID for the animation you want to play.
	@param ... function -- The optional callback function for the animation.

	@return ()
]]
function ViewmodelHelper:PlayAnimation(animationId: string, ...): ()
	-- A little bit of unnecessary typechecking :-)
	if typeof(animationId) ~= "string" then
		warn(string.format("[ViewmodelHelper] - Typeof animationId %q is not a valid type.", typeof(animationId)))
		return
	end

	-- Define the vararg.
	local callback = ...

	-- Grab's the viewmodel animator.
	local Animator: Animator = self._ActiveViewmodel.viewmodel.Humanoid.Animator
	local Animation = Instance.new("Animation")
	Animation.AnimationId = animationId

	-- Setup the track.
	local Track = Animator:LoadAnimation(Animation)
	Track.Looped = false

	-- Play's the track than fire's an ended signal.
	Track:Play()

	self._maid:GiveTask(Track.Ended:Connect(function()
		self.AnimationCompleted:Fire()

		if callback then
			callback()
		end
	end))
end

--[[
	Play's an animation but return's a callback once a certain point is reached.

	@param animId string -- The ID of the animation you want you play.
	@param animEventName string -- The name of the animation event you want to detect.
	@param callback function -- The callback function.
	
	@return any
]]
function ViewmodelHelper:PlayAnimationWithEvent(animId: string, animEventName: string, callback): any
	-- A bit of type checking make sure everything is in order :-)
	if typeof(animId) ~= "string" then
		warn(string.format("[ViewmodelHelper] - Typeof animId %q is not a valid type.", typeof(animId)))
		return
	end

	if typeof(animEventName) ~= "string" then
		warn(string.format("[ViewmodelHelper] - Typeof animEventName %q is not a valid type.", typeof(animEventName)))
		return
	end

	-- Grab's the viewmodel animator.
	local Animator: Animator = self._ActiveViewmodel.viewmodel.Humanoid.Animator
	local Animation = Instance.new("Animation")
	Animation.AnimationId = animId

	-- Setup the track.
	local Track = Animator:LoadAnimation(Animation)
	Track.Looped = false

	-- Play's the track than fire's an ended signal.
	Track:Play()

	-- Return's the callback.
	self._maid:GiveTask(Track:GetMarkerReachedSignal(animEventName):Connect(function()
		callback()
	end))
end
--[[
	Detachs the viewmodel from the player linked to the class.

	@return ()
]]
function ViewmodelHelper:DetachViewmodel(): ()
	if self._ActiveViewmodel ~= nil then
		-- Cleans up and destroys the connection and viewmodel
		self._ActiveViewmodel.viewmodel:Destroy()
		self._ActiveViewmodel.viewmodel = nil
		self._ActiveViewmodel.connection:Disconnect()
		self._ActiveViewmodel.connection = nil

		self._ActiveViewmodel = nil

		print("[ViewmodelHelper] - Sucessfully disconnected the viewmodel from the player.")
	else
		warn("[ViewmodelHelper] - Viewmodel is not attached or not active.")
		return
	end
end

-- ==================
-- === Private API ==
-- ==================

function ViewmodelHelper:Destroy()
	self._maid:DoCleaning()
	print("[ViewmodelHelper] - Sucessfully destroyed ViewmodelHelper.")
end

return ViewmodelHelper
