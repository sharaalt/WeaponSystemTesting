-- External Services
local StateManagerProfile = require(script.Parent.StateManagerProfile)

local loader = require(script.Parent.Parent.loader)
local require = loader.load(script)

-- Internal Services
local BaseObject = require("BaseObject")
local Maid = require("Maid")
local Signal = require("Signal")

local StateManagerClass = setmetatable({}, BaseObject)
StateManagerClass.ClassName = "StateManagerClass"
StateManagerClass.__index = StateManagerClass

function StateManagerClass.new()
	local self = setmetatable(BaseObject.new(), StateManagerClass)

	self._stateCache = {}

	-- Services
	self._maid = Maid.new()

	-- Signals
	self.StateChange = Signal.new()
	self.StateTableCreated = Signal.new()
	self.StateTableRemoved = Signal.new()

	return self
end

--[[
    Creates a stateCache based on specified parameters.

    @param states any -- The states you want to cache.
    @param Player Player -- The player you want to store the state data under.
    @return ()
]]
function StateManagerClass:CreateStateTable(states, Player: Player): ()
	if typeof(Player) ~= "Instance" then -- A bit of type checking.
		warn(string.format("[StateManagerClass] - Type of player %q is not a valid type.", tostring(typeof(Player))))
		return
	end

	local stateCache = self._stateCache

	if stateCache[Player.UserId] then -- Checks if the players cache already exists if so throw a warning.
		warn(
			string.format(
				"[StateManagerClass] - A stateCache already exists for the user with ID %q please update the states instead.",
				Player.UserId
			)
		)
		return
	end

	local newStateTable = StateManagerProfile.CreateStateTable(states, Player)
	self._stateCache[Player.UserId] = newStateTable -- Creates a new table and binds it to the stateCache under the players name.

	self.StateTableCreated:Fire(Player, newStateTable)

	print( -- Prints out success for confirmation.
		string.format(
			"[StateManagerClass] - Sucessfully created a state cache for player with the userId of %q",
			tostring(Player.UserId)
		)
	)
end

--[[
    Set's the state for a specified state under a specified player.

    @param Player Player -- The player who's state you want to change.
    @param StateName string -- The state you want to update.
    @param Data any -- The data you want to add to the state.
]]
function StateManagerClass:SetState(Player: Player, StateName: string, Data: any): ()
	if typeof(Player) ~= "Instance" then -- A bit of type checking.
		warn(string.format("[StateManagerClass] - Type of player %q is not a valid type.", tostring(typeof(Player))))
		return
	end

	if typeof(StateName) ~= "string" then
		warn(
			string.format(
				"[StateManagerClass] - Type of StateName %q is not a valid type.",
				tostring(typeof(StateName))
			)
		)
		return
	end

	local stateCache = self._stateCache
	local playerStates = stateCache[Player.UserId]

	if playerStates.states[StateName] == nil then
		warn(
			string.format(
				"[StateManagerClass] - No state with the name %q in player with userId %q's stateCache..",
				StateName,
				Player.UserId
			)
		)
		return
	end

	playerStates.states[StateName] = Data

	self.StateChange:Fire(Player, StateName, Data)

	print(string.format("[StateManagerClass] - Sucessfully set %q to %q", StateName, tostring(Data)))
end

--[[
    Returns the data of a specified state.

    @param Player player -- The player who's cache you want to access.
    @param StateName string -- The name of the state you want to get data for.
    @return any
]]
function StateManagerClass:GetStateData(Player: Player, StateName: string): any
	if typeof(Player) ~= "Instance" then -- A bit of type checking.
		warn(string.format("[StateManagerClass] - Type of player %q is not a valid type.", tostring(typeof(Player))))
		return
	end

	if typeof(StateName) ~= "string" then
		warn(
			string.format(
				"[StateManagerClass] - Type of StateName %q is not a valid type.",
				tostring(typeof(StateName))
			)
		)
		return
	end

	local stateCache = self._stateCache
	local playerStates = stateCache[Player.UserId] -- Access the players cache.

	if playerStates.states[StateName] ~= nil then -- Checks if the state exists and return's the data.
		print(string.format("[StateManagerClass] - Sucessfully found data for state with the name of %q", StateName))
		return playerStates.states[StateName]
	else -- If not return nil and throw warn.
		warn(string.format("[StateManagerClass] - Cannot find data for state with the name of %q", StateName))
		return nil
	end
end

--[[
    Returns all the cached states.

    @param player Player -- The player who's cache you want to access.
    @return {}
]]
function StateManagerClass:GetStatesBulk(Player: Player): {}
	if typeof(Player) ~= "Instance" then -- Some simple type checking.
		warn(string.format("[StateManagerClass] - Type of player %q is not a valid type.", tostring(typeof(Player))))
		return
	end

	local stateCache = self._stateCache -- Access's the user's cache.
	local playerStates = stateCache[Player.UserId]

	if playerStates then -- If it exists print retrived and return it.
		print(
			string.format(
				"[StateManagerClass] - Sucessfully retrived state data for player with userId %q",
				Player.UserId
			)
		)
		return playerStates.states
	else -- If not throw a warn and return nil.
		warn(string.format("[StateManagerClass] - Cannot find stateData for player with userId %q", Player.UserId))
		return nil
	end
end

--[[
    Destroy's the player's state cache.

    @param Player player -- The player's who's cache you want to remove.
    @return nil
]]
function StateManagerClass:RemoteStateTable(Player: Player): ()
	if typeof(Player) ~= "Instance" then -- Some typechecking.
		warn(string.format("[StateManagerClass] - Type of player %q is not a valid type.", tostring(typeof(Player))))
		return
	end

	local stateCache = self._stateCache[Player.UserId] -- Check if the cache exists.

	if stateCache then -- If so destroy it and print success.
		self._stateCache[Player.UserId] = nil
		print(
			string.format(
				"[StateManagerClass] - Sucessfully destroyed stateCache for player with userId of %q",
				Player.UserId
			)
		)

		self.StateTableRemoved:Fire(Player)

		return
	else -- If not throw an warning.
		warn(
			string.format("[StateManagerClass] - No stateCache exists for player with the userId of %q", Player.UserId)
		)
		return
	end
end

function StateManagerClass:Destroy()
	self._maid:DoCleaning()
	print("[StateManagerClass] - Sucessfully destroyed StateManagerClass.")
end

return StateManagerClass
