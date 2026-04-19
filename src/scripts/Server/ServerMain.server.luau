--[[
	@class ServerMain
]]
local ServerScriptService = game:GetService("ServerScriptService")
local RemoteEvents = game.ReplicatedStorage.Shared.RemoteEvents

local loader = ServerScriptService.ReadyOrNotRoblox:FindFirstChild("LoaderUtils", true).Parent
local require = require(loader).bootstrapGame(ServerScriptService.ReadyOrNotRoblox)

local serviceBag = require("ServiceBag").new()

serviceBag:GetService(require("ReadyOrNotRobloxService"))
serviceBag:Init()
serviceBag:Start()

local fastCast = require(game.ReplicatedStorage.Dependencies.fastcastredux)
local partCache =
	require(game.ReplicatedStorage.Dependencies._Index["encodedvenom_fastcastredux@0.1.3"].fastcastredux.PartCache)

local bulletTemp = Instance.new("Part")
bulletTemp.Size = Vector3.new(1, 1, 1)
bulletTemp.Anchored = true
bulletTemp.BrickColor = BrickColor.new("Bright red")
bulletTemp.Material = Enum.Material.Neon
bulletTemp.CanCollide = false

local CosmeticBulletProvider = partCache.new(bulletTemp, 100, workspace.Bullets)

local castParams = RaycastParams.new()
castParams.IgnoreWater = false
castParams.FilterType = Enum.RaycastFilterType.Exclude
castParams.FilterDescendantsInstances = {}

local cast = fastCast.new()
local castBehaviour = fastCast.newBehavior()
castBehaviour.MaxDistance = 1000
castBehaviour.Acceleration = Vector3.new(0, -workspace.Gravity, 0)
castBehaviour.CosmeticBulletContainer = workspace.Bullets
castBehaviour.HighFidelitySegmentSize = fastCast.HighFidelityBehavior.Default
castBehaviour.RaycastParams = castParams
castBehaviour.CosmeticBulletProvider = CosmeticBulletProvider

fastCast.VisualizeCasts = false

local data = nil

local function onLengthChanged(cast, lastPoint, direction, length, velocity, bullet)
	if bullet then
		local bulletLength = bulletTemp.Size.Z / 2
		local offset = CFrame.new(0, 0, -(length - bulletLength))
		bullet.CFrame = CFrame.lookAt(lastPoint, lastPoint + direction):ToWorldSpace(offset)
	end
end

local function rayHit(cast, result, velocity, bullet)
	if result.Instance.Parent:FindFirstChild("Humanoid") then
		local hitPart = result.Instance

		local character = hitPart.Parent
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			local isHeadshot = (hitPart.Name == "Head")

			if isHeadshot then
				humanoid:TakeDamage(data.HeadshotDamage)
			else
				humanoid:TakeDamage(data.Damage)
			end
		end
	end

	game:GetService("Debris"):AddItem(bullet, 1)
end

RemoteEvents.OnWeaponFireRequest.OnServerEvent:Connect(function(player, d, origin, mouse)
	local direction = (mouse - origin)
	data = d

	cast:Fire(origin, direction, 150, castBehaviour)

	print("[ServerServiceMain] - Client bullet fire request.")
end)

cast.RayHit:Connect(rayHit)
cast.LengthChanged:Connect(onLengthChanged)
