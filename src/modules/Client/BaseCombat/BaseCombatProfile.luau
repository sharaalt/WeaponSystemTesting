local Types = require(script.Parent.Types)

local BaseCombatProfile = {}

function BaseCombatProfile.CreateWeaponDataTable(weaponData: {}): Types.WeaponData
	local newTable: Types.WeaponData = {
		WeaponName = weaponData.WeaponName,
		SoundData = weaponData.SoundData,
		Animations = weaponData.Animations,
		WeaponData = {
			FireMode = 1, -- 1 - SemiAuto, 2 Full-Auto
			Velocity = weaponData.Velocity,
			FireRate = weaponData.FireRate,
			MaxAmmo = weaponData.MaxAmmo,
			Ammo = weaponData.MaxAmmo,
			Damage = weaponData.Damage,
			HeadshotDamage = weaponData.HeadshotDamage,
		},
	}

	print(newTable)

	return newTable
end

return BaseCombatProfile
