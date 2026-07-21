local BaseCombatServiceConstants = {
	-- StateData
	EQUIPPING_STATE_NAME = "Equipping",
	UNEQUIPPING_STATE_NAME = "Unequipping",
	RELOADING_STATE_NAME = "Reloading",
	INSPECTING_STATE_NAME = "Inspecting",
	FIRING_STATE_NAME = "Firing",

	-- Keybind Data
	Keybinds = {
		INSPECT_KEYBIND = Enum.KeyCode.V,
		FIREMODE_KEYBIND = Enum.KeyCode.F,
		RELOAD_KEYBIND = Enum.KeyCode.R,
		FIRE_KEYBIND = Enum.UserInputType.MouseButton1,
		AIM_KEYBIND = Enum.UserInputType.MouseButton2,
	},
}

return BaseCombatServiceConstants
