--[=[
	@class WeaponSystemIteration4Service
]=]

local require = require(script.Parent.loader).load(script)

local ServiceBag = require("ServiceBag")

local WeaponSystemIteration4Service = {}
WeaponSystemIteration4Service.ServiceName = "WeaponSystemIteration4Service"

export type WeaponSystemIteration4Service = typeof(setmetatable(
	{} :: {
		_serviceBag: ServiceBag.ServiceBag,
	},
	{} :: typeof({ __index = WeaponSystemIteration4Service })
))

function WeaponSystemIteration4Service.Init(self: WeaponSystemIteration4Service, serviceBag: ServiceBag.ServiceBag): ()
	assert(not (self :: any)._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")

	-- External
	self._serviceBag:GetService(require("CmdrService"))

	-- Internal
	self._serviceBag:GetService(require("WeaponSystemIteration4Translator"))
end

return WeaponSystemIteration4Service
