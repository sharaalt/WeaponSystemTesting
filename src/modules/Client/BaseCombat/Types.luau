export type stateTable = {
	state: {},
	stateTableAge: number,
	stateTableUser: string,
}

export type WeaponData = {
	WeaponName: string,
	SoundData: {},
	Animations: {},
	WeaponData: {
		FireMode: number, -- 1 - SemiAuto, 2 Full-Auto
		Velocity: number,
		FireRate: number,
		MaxAmmo: number,
		Ammo: number,
		Damage: number,
		HeadshotDamage: number,
	},
}

local Types = {}

return Types
