--!strict
-- Client entry point — asset-import phase.
-- Combat (enemies/bullets/explosions/missiles) is intentionally skipped
-- for now so we can focus on getting the imported GLB jet flying right.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local JetModel = require(Shared:WaitForChild("JetModel"))

local Client = script
local Input = require(Client:WaitForChild("Input"))
local Flight = require(Client:WaitForChild("Flight"))
local Camera = require(Client:WaitForChild("Camera"))
local Hud = require(Client:WaitForChild("Hud"))
local EngineFlames = require(Client:WaitForChild("EngineFlames"))

local player = Players.LocalPlayer
if player.Character then
	player.Character:Destroy()
end

local jet = JetModel.build("PlayerJet")
jet.Parent = Workspace
jet:PivotTo(CFrame.new(0, 600, 0))

local flight = Flight.new(jet)
local input = Input.new()
local cam = Camera.new(Workspace.CurrentCamera)
local hud = Hud.new()

-- Engine flames only attach if the jet has a part named "EngineGlow" (the
-- placeholder does; imported GLBs won't — skip flames cleanly in that case).
local flames: any = nil
if jet:FindFirstChild("EngineGlow") then
	flames = EngineFlames.new(jet)
end

RunService.RenderStepped:Connect(function(dt: number)
	local controls = input:axes()
	for _, a in ipairs(input:drainActions()) do
		if a == "reset" then
			flight:reset()
		elseif a == "toggleView" then
			cam:toggleView()
		end
	end
	flight:update(dt, controls)
	if flames then
		flames:update(flight)
	end
	cam:update(dt, flight)
	hud:update(flight)
end)
