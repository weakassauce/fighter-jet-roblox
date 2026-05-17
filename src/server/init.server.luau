--!strict
-- Minimal stage for asset inspection. No mountains, no trees, no enemies.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

Players.CharacterAutoLoads = false

-- Clean baseplate
local base = Workspace:FindFirstChild("Baseplate")
if base and base:IsA("BasePart") then
	base.Size = Vector3.new(400, 4, 400)
	base.Position = Vector3.new(0, -2, 0)
	base.Color = Color3.fromRGB(80, 95, 90)
	base.Material = Enum.Material.SmoothPlastic
end

-- Soft daylight atmosphere so the jet is well-lit from every angle
local atmos = Lighting:FindFirstChildOfClass("Atmosphere")
if not atmos then
	atmos = Instance.new("Atmosphere")
	atmos.Parent = Lighting
end
atmos.Density = 0.18
atmos.Offset = 0.25
atmos.Color = Color3.fromRGB(205, 220, 235)
atmos.Decay = Color3.fromRGB(120, 130, 150)
atmos.Glare = 0.1
atmos.Haze = 0.6
