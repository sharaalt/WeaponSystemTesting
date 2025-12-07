-- External Services
local RemoteEvents = game.ReplicatedStorage.Shared.RemoteEvents
local RunService = game:GetService("RunService")
local StateTree = require(script.Parent.Parent.Modules.EnemyStateTree)

-- Defenitions
local require: any = (require(script.Parent:WaitForChild("loader")) :: any).load(script)

-- Internal Services
local BaseObject = require("BaseObject")
local Maid = require("Maid")
local Rx = require("Rx")
local Signal = require("Signal")

local BaseEnemyController = setmetatable({}, BaseObject)
BaseEnemyController.ClassName = "BaseEnemyController"
BaseEnemyController.__index = BaseEnemyController

function BaseEnemyController.new(enemy, PathfindingService)
	assert(enemy, "[BaseEnemyController] - Enemy model cannot be nil or false.")
	assert(PathfindingService, "[BaseEnemyController] - PathfindingService cannot be nil or false.")

	print("[BaseEnemyController] - Creating BaseEnemyController...")

	local self = setmetatable(BaseObject.new(), BaseEnemyController)

	-- Dynamic Variables
	self._Enemy = enemy
	self._Players = game:GetService("Players"):GetPlayers()
	self._CurrentState = "State1"
	self._StateFunctions = StateTree.States.State1
	self._TrackedPlayer = nil
	self._HasLineOfSight = false

	-- Services
	self._PathfindingService = PathfindingService
	self._Maid = Maid.new()

	-- Signals
	self._LostLineOfSight = Signal.new()
	self._ChasePlayer = Signal.new()

	task.spawn(function()
		self:MainLoop()
	end)

	return self
end

function BaseEnemyController:MainLoop()
	local PlrService = game:GetService("Players")

	local plrAdded = PlrService.PlayerAdded:Connect(function()
		self._Players = PlrService:GetPlayers()
	end)

	local plrRemove = PlrService.PlayerRemoving:Connect(function()
		self._Players = PlrService:GetPlayers()
	end)

	while true do
		wait(0.1)

		local targetFound = false

		-- Gathering Data --
		for _, v: Player in pairs(self._Players) do
			local character = v.Character or v.CharacterAdded:Wait()
			local distance = (self._Enemy.Head.Position - character.HumanoidRootPart.Position).Magnitude

			if distance < 40 then
				local cast: RaycastResult = self:_GetLineOfSight(
					character.HumanoidRootPart.Position,
					self._Enemy.PrimaryPart.Position,
					character
				)

				if cast then
					local Player = PlrService:GetPlayerFromCharacter(cast.Instance.Parent)

					if Player then
						print(cast)
						print("[BaseEnemyController] - Has line of sight.")
						self._TrackedPlayer = v
						self._HasLineOfSight = true
						targetFound = true
					else
						targetFound = false
						warn("[BaseEnemyController] - Line of sight is not a valid player.")
					end
				else
					targetFound = false
					warn("[BaseEnemyController] - Lost line of sight.")
				end
			end
		end

		if targetFound then
			if self._CurrentState ~= "State2" then
				self:_SetState("State2")
				print("[BaseEnemyController] - Switching state to State 2.")
			end
		else
			if self._CurrentState ~= "State1" then
				self:_SetState("State1")
				print("[BaseEnemyController] - Switching state to State 1.")
			end
		end

		self._StateFunctions.Execute(self)
	end

	self._Maid:GiveTask(plrAdded, plrRemove)
end

function BaseEnemyController:_SetState(stateName)
	if typeof(stateName) ~= "string" then
		error(`[BaseEnemyController] - The type of stateName is not a proper type.`)
		return
	end

	if self._CurrentState == stateName then
		warn("[BaseEnemyController] - The state is already the same state.")
		return
	end

	if self._StateFunctions then
		self._StateFunctions.Exit(self)
		self._StateFunctions = StateTree.ReturnStateData(stateName)
		self._CurrentState = stateName
		self._StateFunctions.Enter(self)
		print("[BaseEnemyController] - State sucessfully set.")
	end
end

function BaseEnemyController:_GetLineOfSight(vector1, vector2, v)
	assert(vector1, "[BaseEnemyController] - vector1 is nil or false.")
	assert(vector2, "[BaseEnemyController] - vector2 is nil or false.")

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { self._Enemy }

	local direction = (vector1 - vector2)

	local rayCast = workspace:Raycast(vector2, direction, params)
	-- self:_VisualizeRay(vector2, vector1)
	return rayCast
end

function BaseEnemyController:_VisualizeRay(start, endPoint)
	local distance = (start - endPoint).Magnitude
	local center = (start + endPoint) / 2

	if self._LinePart then
		self._LinePart:Destroy()
		self._LinePart = nil
	end

	self._LinePart = Instance.new("Part")
	self._LinePart.Parent = workspace
	self._LinePart.BrickColor = BrickColor.new("Really red")
	self._LinePart.CanCollide = false
	self._LinePart.Anchored = true
	self._LinePart.Name = "LinePart"
	self._LinePart.Size = Vector3.new(0.2, 0.2, distance)
	self._LinePart.CFrame = CFrame.lookAt(center, endPoint)
end

function BaseEnemyController:Destory()
	self._Maid:DoCleaning()
	print("[BaseEnemyController] - All cleaned up.")
end

return BaseEnemyController
