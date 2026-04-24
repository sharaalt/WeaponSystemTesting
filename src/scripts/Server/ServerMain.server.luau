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
bulletTemp.Size = Vector3.new(0.001, 0.5, 0.5)
bulletTemp.Anchored = true
bulletTemp.Transparency = 1
bulletTemp.Material = Enum.Material.Neon
bulletTemp.CanCollide = false

local attachment0 = Instance.new("Attachment")
attachment0.Parent = bulletTemp
attachment0.Position = Vector3.new(0, 0.504, 0)

local attcachment1 = Instance.new("Attachment")
attcachment1.Parent = bulletTemp
attcachment1.Position = Vector3.new(0, -0.496, 0)

local trail = Instance.new("Trail")
trail.Parent = bulletTemp
trail.Attachment0 = attachment0
trail.Attachment1 = attcachment1
trail.MaxLength = 3
trail.MinLength = 0
trail.Lifetime = 0.5
trail.FaceCamera = true
trail.Color = ColorSequence.new(Color3.fromRGB(253, 255, 119))

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

local function rayHit(_cast, result: RaycastResult, _velocity, bullet: Part)
	local hitPart = result.Instance
	local character = hitPart:FindFirstAncestorOfClass("Model")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if humanoid and humanoid.Health > 0 then
		local damage = (hitPart.Name == "Head") and data.HeadshotDamage or data.Damage
		humanoid:TakeDamage(damage)
	else
		local tPart = Instance.new("Part") -- Create's a temporary impact decal.
		tPart.Anchored = true
		tPart.Position = result.Position
		tPart.Rotation = Vector3.new(
			result.Instance.Orientation.X,
			result.Instance.Orientation.Y + 90,
			result.Instance.Orientation.Z
		)
		tPart.Parent = workspace
		tPart.Size = Vector3.new(0.001, 0.5, 0.5)
		tPart.Transparency = 1

		local impactDecal = Instance.new("Decal")
		impactDecal.Parent = tPart
		impactDecal.Face = "Left"
		impactDecal.Texture = "rbxassetid://11645179630"

		local impactDecal2 = Instance.new("Decal") -- The stupidest fix to the issue.. Ah well.
		impactDecal2.Parent = tPart
		impactDecal2.Face = "Right"
		impactDecal2.Texture = "rbxassetid://11645179630"
	end

	bullet:Destroy()
end

RemoteEvents.OnWeaponFireRequest.OnServerEvent:Connect(function(_player, newData, origin, mouse)
	local direction = (mouse - origin)
	data = newData

	cast:Fire(origin, direction, newData.Velocity, castBehaviour)

	print("[ServerServiceMain] - Client bullet fire request.")
end)

cast.RayHit:Connect(rayHit)
cast.LengthChanged:Connect(onLengthChanged)
