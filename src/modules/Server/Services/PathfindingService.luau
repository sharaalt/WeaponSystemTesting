-- Defenitions
local require: any = (require(script.Parent:WaitForChild("loader")) :: any).load(script)

-- External Services
local PS = game:GetService("PathfindingService")

-- Internal Services
local BaseObject = require("BaseObject")
local Maid = require("Maid")
local Promise = require("Promise")
local Rx = require("Rx")
local Signal = require("Signal")

local PathfindingService = setmetatable({}, BaseObject)
PathfindingService.ClassName = "PathfindingService"
PathfindingService.__index = PathfindingService

function PathfindingService:Init(serviceBag)
	assert(not self._serviceBag, "[PathfindingService] - ServiceBag already initalizied!")

	-- Services
	self._Maid = Maid.new()
	self._serviceBag = serviceBag
end

function PathfindingService:CreateWaypoints(StartPos, EndPos)
	return Promise.new(function(succ, err)
		local path = PS:CreatePath({
			AgentRadius = 3,
			AgentHeight = 6,
			AgentCanJump = false,
			AgentCanClimb = true,
		})

		local success, errorMessage = pcall(function()
			path:ComputeAsync(StartPos, EndPos)
		end)

		-- Confirm the computation was successful
		if success and path.Status == Enum.PathStatus.Success then
			-- For each waypoint, create a part to visualize the path
			succ(path)
		else
			err(print(`Path unable to be computed, error: {errorMessage}`))
		end
	end)
end

return PathfindingService
