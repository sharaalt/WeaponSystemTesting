--[[
    @author sharafzada
    @class StateManager.luau
    @version 1.0.0

    -- To-do list:
    @todo Everything :0

    The StateManager class is meant to work with the BaseCombatService as a helper class to aid with states i.e. Equipping, Unequipping, etc. To prevent the BaseCombat folder
    from getting to big StateManager is put in it's own StateManager folder which makes it easier to handle/work with.
]]

-- External Services
local StateManagerProfile = require(script.Parent.StateManagerProfile)
local Types = require(script.Parent.Types)

local loader = require(script.Parent.Parent.loader)
local require = loader.load(script)

-- Internal Services
local BaseObject = require("BaseObject")
local Maid = require("Maid")
local Signal = require("Signal")

local StateManager = setmetatable({}, BaseObject)
StateManager.ServiceName = "StateManager"
StateManager.__index = StateManager

function StateManager.new()
	local self = setmetatable(BaseObject.new(), StateManager)

	-- Variables
	self._StateCache = {}

	-- Services
	self._maid = Maid.new()

	-- Signals
	self.StateCreated = Signal.new()
	self.StateUpdated = Signal.new()
	self.StateDeleted = Signal.new()

	return self
end

-- ==================
-- === Public API ===
-- ==================
--[[
    Add's a new state to the state cache based on inputted data.

    @param StateName string -- The name of the state you want to create.
    @param StateValue any -- The value of the state you want to create.

    @return ()
]]
function StateManager:AddState(StateName: string, StateValue: any): ()
	if typeof(StateName) ~= "string" then
		warn(string.format("[StateManager] - Type of StateName %q is not a valid type.", typeof(StateName)))
		return
	end

	if typeof(StateValue) == "nil" then
		warn("[StateManager] - Type of StateValue cannot be nil.")
		return
	end

	if self._StateCache[StateName] then
		warn(string.format("[StateManager] - An active state already exists with the name %q", StateName))
		return
	end

	-- Create's a formatted table.
	local CacheTable = StateManagerProfile.CreateCacheTable(StateName, StateValue)

	-- Although theoretically not possible in the even a cache table isn't made have some logic to handle that.
	if CacheTable then
		-- Attach the state to the cache and notify creation.
		self._StateCache[StateName] = CacheTable

		-- Fire's a StateCreated function and provides the table for access.
		self.StateCreated:Fire(StateName, CacheTable)
		print(string.format("[StateManager] - Sucessfully created state with the name %q", StateName))
	else
		warn("[StateManager] - CacheTable was not able to be generated.")
		return
	end
end

--[[
    Update's the value of a state in the cache.

    @param StateName string -- The name of the state you want to update the value for.
    @param Value any -- The value you want to update the state to.

    @return ()
]]
function StateManager:UpdateStateValue(StateName: string, Value: any): ()
	-- Make sure that StateName is a string or it'll most likely break logic.
	if typeof(StateName) ~= "string" then
		warn(string.format("[StateManager] - Type of StateName %q is not a valid type.", typeof(StateName)))
		return
	end

	-- Grab's the state to see if it exists.
	local State = self._StateCache[StateName]

	-- Check's if the state actually exists.
	if State then
		-- Update the value if it does actually exist.
		State.StateValue = Value

		print(string.format("[StateManager] - Sucessfully updated %q to %q", StateName, tostring(Value)))

		-- Fire's a signal that indicate's a state update.
		self.StateUpdated:Fire(StateName)
		return
	else
		-- Throw a warning if it doesn't.
		warn(string.format("[StateManager] - No state exsits with the name %q", StateName))
		return
	end
end

--[[
    Remove's a state from the cache based off of name.

    @param StateName string -- The name of the state you want to remove.

    @return ()
]]
function StateManager:RemoveState(StateName: string): ()
	-- Make sure that StateName is a string or it'll most likely break logic.
	if typeof(StateName) ~= "string" then
		warn(string.format("[StateManager] - Type of StateName %q is not a valid type.", typeof(StateName)))
		return
	end

	-- Grab the state
	local State = self._StateCache[StateName]

	-- Check if the state exists if not throw a warnning.
	if State then
		-- If it exists destroy/delete the state.
		self._StateCache[StateName] = nil

		-- Fire's a StateDeleted signal to signify the state has been deleted.
		self.StateDeleted:Fire(StateName)
		print(string.format("[StateManager] - Sucessfully deleted %q from the state cache.", StateName))
	else
		warn(string.format("[StateManager] - No state exists with the name %q", StateName))
		return
	end
end

--[[
	Retrive's all states in the state cache.

	@return {Types.CacheTable}
]]
function StateManager:GetAllStates(): { [string]: Types.CacheTable }
	return self._StateChache
end

-- ==================
-- === Private API ==
-- ==================
function StateManager:Destroy()
	self._maid:DoCleaning()
	print("[StateManager] - Sucessfully destroyed StateManager.")
end

return StateManager
