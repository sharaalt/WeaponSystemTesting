local Types = {}

export type ViewmodelData = {
	ViewmodelObject: Model,
	ViewmodelConnection: RBXScriptConnection,
}

export type WeaponData = {
	-- Basic Data
	Equipped: boolean,
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
	WeaponInspectAnim: string,
}

export type WeaponTable = {
	Tool: Tool,
	WeaponData: { WeaponData },
}

return Types
