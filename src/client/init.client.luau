--!strict
-- Client entry point: build placeholder jet, wire input + flight + camera + HUD.

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

-- Server has disabled CharacterAutoLoads. Defensive: if one slipped in, remove it.
local player = Players.LocalPlayer
if player.Character then
	player.Character:Destroy()
end

-- Build the jet in workspace
local jet = JetModel.build("PlayerJet")
jet.Parent = Workspace
jet:PivotTo(CFrame.new(0, 600, 0))

local flight = Flight.new(jet)
local input = Input.new()
local cam = Camera.new(Workspace.CurrentCamera)
local hud = Hud.new()

RunService.RenderStepped:Connect(function(dt)
	local controls = input:axes()
	for _, a in ipairs(input:drainActions()) do
		if a == "reset" then
			flight:reset()
		elseif a == "toggleView" then
			cam:toggleView()
		end
	end
	flight:update(dt, controls)
	cam:update(dt, flight)
	hud:update(flight)
end)
