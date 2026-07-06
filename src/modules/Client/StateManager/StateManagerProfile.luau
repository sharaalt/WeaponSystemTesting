--[[
    @author sharfzada
    @class StateManagerProfile.luau
    @version 1.0.0

    A module containing helper functions for StateManager modules.
]]

local Types = require(script.Parent.Types)

local StateManagerProfile = {}

--[[
    Create's a state cache table and return it.    

    @param StateName string -- The name of the state you want to create a table for.
    @param StateValue any -- The value of the state you want to create a table for.
]]
function StateManagerProfile.CreateCacheTable(StateName: string, StateValue: any): Types.CacheTable
	-- A bit of typechecking :-)
	if typeof(StateName) ~= "string" then
		warn(string.format("[StateManagerProfile] - Type of StateName %q is not a valid type.", typeof(StateName)))
		return
	end

	if typeof(StateValue) == "nil" then
		warn("[StateManagerProfile] - Type of StateValue cannot be nil.")
		return
	end

	-- Creation of the table.
	local CacheTable: Types.CacheTable = {
		StateName = StateName,
		StateCreated = os.clock(),
		StateValue = StateValue,
	}

	return CacheTable
end

return StateManagerProfile
