local Tree = {
	States = {
		State1 = {
			StateName = "State1",
			Enter = function(self)
				print("Enetering State1")
			end,
			Execute = function(self)
				print(self)
			end,
			Exit = function(self)
				print("Exiting State1")
			end,
		},
		State2 = {
			StateName = "State2",
			Enter = function(self)
				print(self)
			end,
			Execute = function(self)
				print("Executing State2")
			end,
			Exit = function(self)
				print("Exiting State2")
			end,
		},
	},
}

function Tree.ReturnStateData(StateName)
	for i, v in pairs(Tree.States) do
		if i == StateName then
			return v
		end
	end
end

return Tree
