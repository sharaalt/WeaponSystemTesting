local StateTypes = require(script.Parent.Parent.StateManager.Types)

local Types = {}

export type StateData = {
	_stateBrio: any,
	_states: { StateTypes.CacheTable },
	_weaponData: WeaponData,
}

export type ViewmodelData = {
	ViewmodelObject: Model,
	ViewmodelConnection: RBXScriptConnection,
}

export type WeaponData = {
	-- Basic Data
	WeaponName: string,
	Ammo: number,
	MaxAmmo: number,
	WeaponAimSpeed: number,

	-- Damage Data
	BaseDamage: number,
	HeadshotDamage: number,

	-- Animations
	WeaponEquipAnim: string,
	WeaponFireAnim: string,
	WeaponReloadAnim: string,
	WeaponUnequipAnim: string,
	WeaponInspectAnim: string,
}

export type WeaponTable = {
	Tool: Tool,
	WeaponData: { WeaponData },
}

return Types
