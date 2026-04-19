local Types = require(script.Parent.Types)

local StateManagerProfile = {}

function StateManagerProfile.CreateStateTable(states: {}, Player: Player): Types.stateTable
	if typeof(Player) ~= "Instance" then
		warn(string.format("[StateManagerProfile] - Type of player %q is not a valid type,", tostring(typeof(Player))))
		return
	end

	local newStateTable: Types.stateTable = {
		states = states,
		stateTableAge = os.clock(),
		stateTableUser = Player.UserId,
	}

	return newStateTable
end

return StateManagerProfile
