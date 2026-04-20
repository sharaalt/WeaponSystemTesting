--[=[
	@class ReadyOrNotRobloxServiceClient
]=]

local require = require(script.Parent.loader).load(script)

local ReadyOrNotRobloxServiceClient = {}
ReadyOrNotRobloxServiceClient.ServiceName = "ReadyOrNotRobloxServiceClient"

function ReadyOrNotRobloxServiceClient:Init(serviceBag: ServiceBag.ServiceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")

	-- External
	self._serviceBag:GetService(require("CmdrServiceClient"))

	-- Internal
	self._serviceBag:GetService(require("ReadyOrNotRobloxTranslator"))
end

return ReadyOrNotRobloxServiceClient