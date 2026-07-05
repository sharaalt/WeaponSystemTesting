--[[
	@author sharafzada
	@class BaseCombatProfile.luau
	@version 1.0.0

	A small module made to assist BaseCombatService and other sub-modules within the BaseCombat service by providing minor helper functions.
]]

local Types = require(script.Parent.Types)

local BaseCombatProfile = {}

--[[
    Format's the user's tool and WeaponData into a Types.WeaponTable form.

    @param tool Tool -- The tool you want to format for.
    @param WeaponData any -- The weapon data you want to format with.

    @return Types.WeaponTable
]]
function BaseCombatProfile.FormatTable(tool: Tool, WeaponData: any): Types.WeaponTable
	-- Although not technically needed I usually prefer to keep it here just for saftey.
	if typeof(tool) ~= "Instance" then
		warn(string.format("[BaseCombatProfile] - Type of tool %q is not a valid type.", typeof(tool)))
		return
	end

	local FormattedTable: Types.WeaponTable = {
		Tool = tool,
		WeaponData = BaseCombatProfile._FormatWeaponData(WeaponData),
	}

	return FormattedTable
end

--[[
	Format's the viewmodel data into a Types.ViewmodelData form.

	@param viewmodel Instance -- The viewmodel you want to format for.
	@param connection RBXScriptConnection -- The connection to the renderstepped function.
]]
function BaseCombatProfile.FormatViewmodelTable(
	viewmodel: Instance,
	connection: RBXScriptConnection
): Types.ViewmodelData
	-- Although not technically needed I usually prefer to keep it here just for saftey.
	if typeof(viewmodel) ~= "Instance" then
		warn(string.format("[BaseCombatProfile] - Type of viewmodel %q is not a valid type.", typeof(viewmodel)))
		return
	end

	if typeof(connection) ~= "RBXScriptConnection" then
		warn(string.format("[BaseCombatProfile] - Type of connection %q is not a valid type.", typeof(connection)))
		return
	end

	local FormattedViewmodelTbl: Types.ViewmodelData = {
		viewmodel = viewmodel,
		connection = connection,
	}

	return FormattedViewmodelTbl
end

--[[
    Format's the base weapon data into a Types.WeaponData form.

    @param WeaponData any -- The base data for the weapon.
    @return Types.WeaponData
]]
function BaseCombatProfile._FormatWeaponData(WeaponData: any): Types.WeaponData
	local realData = require(WeaponData) -- We pass by value instead of require due to nevermore restrictions :-(

	-- The new "treated" table.
	local newTbl: Types.WeaponData = {
		Equipped = false,
		Ammo = realData.MaxAmmo,
		MaxAmmo = realData.MaxAmmo,
		WeaponAimSpeed = realData.WeaponAimSpeed,

		BaseDamage = realData.BaseDamage,
		HeadshotDamage = realData.HeadshotDamage,

		WeaponEquipAnim = realData.ReturnAnimByName("WeaponEquipAnim"),
		WeaponFireAnim = realData.ReturnAnimByName("WeaponFireAnim"),
		WeaponReloadAnim = realData.ReturnAnimByName("WeaponReloadAnim"),
		WeaponInspectAnim = realData.ReturnAnimByName("WeaponInspectAnim"),
	}

	return newTbl
end

return BaseCombatProfile
