--!strict
--[=[
	@class WeaponSystemIteration4ServiceClient
]=]

local require = require(script.Parent.loader).load(script)

local ServiceBag = require("ServiceBag")

local WeaponSystemIteration4ServiceClient = {}
WeaponSystemIteration4ServiceClient.ServiceName = "WeaponSystemIteration4ServiceClient"

export type WeaponSystemIteration4ServiceClient =
	typeof(setmetatable(
		{} :: {
			_serviceBag: ServiceBag.ServiceBag,
		},
		{} :: typeof({ __index = WeaponSystemIteration4ServiceClient })
	))

function WeaponSystemIteration4ServiceClient.Init(self: WeaponSystemIteration4ServiceClient,serviceBag: ServiceBag.ServiceBag): ()
	assert(not (self :: any)._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")

	-- External
	self._serviceBag:GetService(require("CmdrServiceClient"))

	-- Internal
	self._serviceBag:GetService(require("WeaponSystemIteration4Translator"))
end

return WeaponSystemIteration4ServiceClient
