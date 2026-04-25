local Types = require(script.Parent.Types)
local ContextActionService = game:GetService("ContextActionService")

local MobileInputProfile = {}

function MobileInputProfile.createBindTable(
	ActionName: string,
	Id: number,
	InputEnum: EnumItem,
	UnbindFunc: Types.unbind
): Types.cacheTable
	if typeof(Id) ~= "number" then
		warn(string.format("[InputServiceProfile] - Type of Id %q is not a valid type.", typeof(Id)))
		return
	end

	if typeof(InputEnum) ~= "EnumItem" then
		warn(string.format("[InputServiceProfile] - Type of InputEnum %q is not a valid type.", typeof(InputEnum)))
		return
	end

	if typeof(ActionName) ~= "string" then
		warn(string.format("[InputServiceProfile] - Type of ActionName %q is not a valid type.", typeof(ActionName)))
		return
	end

	local bindedTbl: Types.cacheTable = {
		Name = tostring(ActionName),
		Id = Id,
		InputEnum = InputEnum,

		Unbind = UnbindFunc(),

		SetTitle = function(self, title: string)
			ContextActionService:SetTitle(self.Name, title)
		end,

		SetImage = function(self, imageAsset: string)
			ContextActionService:SetImage(self.Name, imageAsset)
		end,

		SetPosition = function(self, position: UDim2)
			ContextActionService:SetPosition(self.Name, position)
		end,

		GetButton = function(self)
			return ContextActionService:GetButton(self.Name)
		end,
	}

	return bindedTbl
end

return MobileInputProfile
