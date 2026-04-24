local AudioServiceData = {
	Sounds = {
		["FireSound"] = { Id = "rbxassetid://5096003821" },
		["ReloadSound"] = { Id = "rbxassetid://104445304303143" },
		["EquipSound"] = { Id = "rbxassetid://104445304303143" },
		["InspectSound"] = { Id = "rbxassetid://131169866964949" },
		["FireSelectorSound"] = { Id = "rbxassetid://111236667677398" },
		["UnequipSound"] = { Id = "rbxassetid://109520982059397" },
	},
}

function AudioServiceData.returnAudio()
	return AudioServiceData.Sounds
end

return AudioServiceData
