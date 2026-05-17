--!strict
-- Server bootstrap: disable Humanoid character autoload (the player flies a jet,
-- not a humanoid) and build a vast landscape (mountains + scattered trees).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

Players.CharacterAutoLoads = false

-- Ensure there's a baseplate / ocean floor
local existingBase = Workspace:FindFirstChild("Baseplate")
if existingBase and existingBase:IsA("BasePart") then
	existingBase.Size = Vector3.new(8000, 4, 8000)
	existingBase.Position = Vector3.new(0, -2, 0)
	existingBase.Color = Color3.fromRGB(60, 95, 50)
	existingBase.Material = Enum.Material.Grass
end

-- Sun atmosphere
local atmos = Lighting:FindFirstChildOfClass("Atmosphere")
if not atmos then
	atmos = Instance.new("Atmosphere")
	atmos.Parent = Lighting
end
atmos.Density = 0.32
atmos.Offset = 0.25
atmos.Color = Color3.fromRGB(199, 220, 240)
atmos.Decay = Color3.fromRGB(102, 119, 145)
atmos.Glare = 0.2
atmos.Haze = 1.4

local function makeMountain(name: string, pos: Vector3, size: Vector3, color: Color3)
	local m = Instance.new("Part")
	m.Name = name
	m.Anchored = true
	m.Size = size
	m.Position = pos
	m.Color = color
	m.Material = Enum.Material.Rock
	m.TopSurface = Enum.SurfaceType.Smooth
	m.BottomSurface = Enum.SurfaceType.Smooth
	m.Parent = Workspace
	return m
end

-- Sprinkle ~28 mountain blocks across the playable area, with snowy tops.
for i = 1, 28 do
	local r = 700 + math.random() * 3200
	local a = math.random() * math.pi * 2
	local x = math.cos(a) * r
	local z = math.sin(a) * r
	local h = 250 + math.random() * 600
	makeMountain(
		"Mountain" .. i,
		Vector3.new(x, h / 2, z),
		Vector3.new(160 + math.random(0, 240), h, 160 + math.random(0, 240)),
		Color3.fromRGB(96, 86, 78)
	)
	-- Snowcap on top
	if h > 500 then
		makeMountain(
			"Snowcap" .. i,
			Vector3.new(x, h - 30, z),
			Vector3.new(140, 60, 140),
			Color3.fromRGB(238, 244, 248)
		)
	end
end

-- Tree scatter (simple two-part trees) — limited count so we don't lag.
local function makeTree(x: number, z: number)
	local y = 0
	local trunk = Instance.new("Part")
	trunk.Anchored = true
	trunk.CanCollide = false
	trunk.CanQuery = false
	trunk.Size = Vector3.new(2, 16, 2)
	trunk.Position = Vector3.new(x, y + 8, z)
	trunk.Color = Color3.fromRGB(90, 60, 35)
	trunk.Material = Enum.Material.Wood
	trunk.Parent = Workspace

	local leaves = Instance.new("Part")
	leaves.Anchored = true
	leaves.CanCollide = false
	leaves.CanQuery = false
	leaves.Shape = Enum.PartType.Ball
	leaves.Size = Vector3.new(14, 14, 14)
	leaves.Position = Vector3.new(x, y + 22, z)
	leaves.Color = Color3.fromRGB(44, 100, 50)
	leaves.Material = Enum.Material.Grass
	leaves.Parent = Workspace
end

for _ = 1, 220 do
	local x = (math.random() - 0.5) * 6500
	local z = (math.random() - 0.5) * 6500
	-- Avoid placing inside mountain footprints by skipping points near them
	makeTree(x, z)
end
