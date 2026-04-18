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

-- ========================
-- ====== Public API ======
-- ========================
function ViewmodelClass:bindViewmodel(object: Instance, viewmodelName: string)
	if self._viewmodel then
		warn("[ViewmodelClass] - A viewmodel is already binded.")
		return
	end

	if typeof(object) ~= "Instance" then
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

	local pathToViewmodel: Model = game.ReplicatedStorage.Shared.Viewmodels[viewmodelName]

	if pathToViewmodel then
		self._viewmodel = pathToViewmodel:Clone()
		self._viewmodel.Parent = workspace

		self._viewmodelFunc = RunService.RenderStepped:Connect(function(a0: number)
			self._viewmodel.PrimaryPart.CFrame = object.CFrame
		end)
	else
		warn(string.format("[ViewmodelClass] - No viewmodel exists with the name %q", tostring(viewmodelName)))
	end
end

function ViewmodelClass:unbindViewmodel()
	self._viewmodelFunc:Disconnect()
	self._viewmodelFunc = nil
	self._viewmodel:Destroy()
	self._viewmodel = nil
end

-- ========================
-- ====== Private API =====
-- ========================

return ViewmodelClass
