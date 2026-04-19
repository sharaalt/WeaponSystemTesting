local BaseCombatConstanants = {
	States = {
		Equipping = false,
		UnEquipping = false,
		Reloading = false,
		Aiming = false,
		Firing = false,
		Inspecting = false,
		FireMode = false,
		HoldingMb1 = false,
		IdleAnimation = false,
	},
}

function BaseCombatConstanants.GetStates()
	return BaseCombatConstanants.States
end

return BaseCombatConstanants
