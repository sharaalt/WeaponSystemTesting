-- External Services
local AudioServiceData = require(script.Parent.Parent.Parent.Shared.AudioServiceData)
local Players = game:GetService("Players")

local loader = require(script.Parent.Parent.loader)
local require = loader.load(script)

-- Internal Services
local Maid = require("Maid")
local Signal = require("Signal")

local AudioServiceClient = {}
AudioServiceClient.ServiceName = "BaseCombatService"

function AudioServiceClient:Init(serviceBag)
	assert(not self._serviceBag, "[AudioServiceClient] - AudioServiceClient already initalized.")

	self._serviceBag = assert(serviceBag, "[AudioServiceClient] - AudioServiceClient is already initalized!")

	-- Internal Services
	self._maid = Maid.new()

	-- Variables
	self._audioCache = {}

	-- Signals
	self.AudioPlayed = Signal.new()
	self.AudioEnded = Signal.new()

	self._maid:GiveTask(task.spawn(function()
		self:_cacheAudio()
	end))
end

-- ======================
-- ===== Public API =====
-- ======================
--[[
    Plays a specified audio.

    @param audioName string -- The cached audio you want to play.
    @param ... boolean -- Whether the audio is looped or not.
    @return Instance
]]
function AudioServiceClient:PlayAudio(audioName: string, ...: boolean): Instance
	if typeof(audioName) ~= "string" then
		warn(
			string.format(
				"[AudioServiceClient] - Type of audioName %q is not a valid type.",
				tostring(typeof(audioName))
			)
		)
		return
	end

	if not self._audioCache[audioName] then
		warn(string.format("[AudioServiceClient] - Cannot find any cached audio with the name %q", audioName))
		return
	end

	local newAudio = Instance.new("Sound")
	newAudio.Parent = Players.LocalPlayer -- Switch this to be passed in.
	newAudio.SoundId = self._audioCache[audioName].Id
	newAudio.Looped = ... or false

	newAudio:Play()

	print("[AudioServiceClient] - Sucessfully played audio!")

	self.AudioPlayed:Fire()

	if ... then
		return newAudio
	else
		self._maid:GiveTask(newAudio)
	end
end

-- =======================
-- ===== Private API =====
-- =======================
--[[
    Cache's the audio from pre-existsing files into the audio service client.

    @return ()
]]
function AudioServiceClient:_cacheAudio(): ()
	for i, v in pairs(AudioServiceData.returnAudio()) do
		self._audioCache[i] = v
	end
end

return AudioServiceClient
