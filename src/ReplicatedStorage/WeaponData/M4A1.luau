local M4A1 = {
	-- Base Data
	WeaponName = "M4A1",
	Ammo = 30,
	MaxAmmo = 30,
	WeaponAimSpeed = 0.2,

	-- Damage Data
	BaseDamage = 10,
	HeadshotDamage = 20,

	-- Sounds
	Sounds = {
		FireSound = { Id = "rbxassetid://5096003821" },
		EquipSound = { Id = "rbxassetid://104445304303143" },
		UnequipSound = { Id = "rbxassetid://104445304303143" },
		FireModeSound = { Id = "rbxassetid://131169866964949" },
		ReloadSound = { Id = "rbxassetid://111236667677398" },
		InspectSound = { Id = "rbxassetid://109520982059397" },
	},

	-- Animations
	Animations = {
		WeaponEquipAnim = "rbxassetid://93263765397131",
		WeaponUnequipAnim = "rbxassetid://104773513340363",
		WeaponFireAnim = "rbxassetid://116920988262292",
		WeaponReloadAnim = "",
		WeaponInspectAnim = "rbxassetid://136612778191367",
	},
}

function M4A1.ReturnAnimations(): { string }
	return M4A1.Animations
end

function M4A1.ReturnAnimByName(tblName: string): string
	return M4A1.Animations[tblName]
end

return M4A1
