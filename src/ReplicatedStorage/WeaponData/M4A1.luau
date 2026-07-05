local M4A1 = {
	-- Base Data
	WeaponName = "M4A1",
	Ammo = 30,
	MaxAmmo = 30,
	WeaponAimSpeed = 0.2,

	-- Damage Data
	BaseDamage = 10,
	HeadshotDamage = 20,

	-- Animations
	Animations = {
		WeaponEquipAnim = "rbxassetid://93263765397131",
		WeaponFireAnim = "",
		WeaponReloadAnim = "",
		WeaponInspectAnim = "",
	},
}

function M4A1.ReturnAnimations(): { string }
	return M4A1.Animations
end

function M4A1.ReturnAnimByName(tblName: string): string
	return M4A1.Animations[tblName]
end

return M4A1
