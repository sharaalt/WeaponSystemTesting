local M4A1 = {
	WeaponName = "M4A1",

	SoundData = {
		FireSound = "rbxassetid://5096003821",
		ReloadSound = "rbxassetid://104445304303143",
		FirstTimeEquipSound = "rbxassetid://104445304303143",
		InspectSound = "rbxassetid://131169866964949",
		FireSelectorSound = "rbxassetid://111236667677398",
		SecondEquipGood = "rbxassetid://120440060500004",
		UnequipSound = "rbxassetid://109520982059397",
	},

	Animations = {
		Idle = "rbxassetid://77887609433917",
		ReloadWithNoAmmo = "rbxassetid://124179811038132",
		ReloadWithAmmo = "rbxassetid://124179811038132",
		Equip = "rbxassetid://93263765397131",
		Shooting = "rbxassetid://116920988262292",
		FireSelector = "rbxassetid://80282292340284",
		SecondEquip = "rbxassetid://120607258519527",
		UnEquip = "rbxassetid://104773513340363",
		Inspect = "rbxassetid://136612778191367",
		CheckingAmmo = "rbxassetid://115621647051973",
	},

	ServerAnimations = {
		Idle = "rbxassetid://107832596680731",
	},

	Velocity = 500,
	FireRate = 0.1,
	MaxAmmo = 25,
	Damage = 10,
	HeadshotDamage = 15,
	EquippedBefore = false,
	ViewmodelPath = game.ReplicatedStorage.Shared.Viewmodels.M4A1,
}

function M4A1.ReturnData()
	return M4A1
end

function M4A1.ReturnTable(name)
	return M4A1[name]
end

function M4A1.ReturnSoundData(name)
	return M4A1.SoundData[name]
end

return M4A1
