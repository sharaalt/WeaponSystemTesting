--[=[
	@class ReadyOrNotRobloxService
]=]

local require = require(script.Parent.loader).load(script) :: any

local ReadyOrNotRobloxService = {}
ReadyOrNotRobloxService.ServiceName = "ReadyOrNotRobloxService"

function ReadyOrNotRobloxService:Init(serviceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")

	-- External
	self._serviceBag:GetService(require("CmdrService"))

	-- Internal
	self._serviceBag:GetService(require("ReadyOrNotRobloxTranslator"))
end

return ReadyOrNotRobloxService
