--!strict
-- Asset-inspection mode: build the jet, no flight / no HUD / no combat.
-- Left/right mouse drag orbits around the jet, scroll wheel zooms.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local JetModel = require(Shared:WaitForChild("JetModel"))

local player = Players.LocalPlayer
if player.Character then
	player.Character:Destroy()
end

-- Build the jet (cycle through: imported .rbxm → mesh data → placeholder).
print("[init] building jet...")
local okBuild, jetOrErr = pcall(JetModel.build, "PlayerJet")
local jet: Model
if okBuild and jetOrErr then
	jet = jetOrErr :: Model
else
	warn("[init] JetModel.build errored:", jetOrErr)
	-- Last-resort red cube so something is on screen
	jet = Instance.new("Model")
	local p = Instance.new("Part")
	p.Size = Vector3.new(20, 4, 10)
	p.Color = Color3.fromRGB(255, 80, 80)
	p.Anchored = true
	p.CanCollide = false
	p.Parent = jet
	jet.PrimaryPart = p
end
jet.Parent = Workspace
jet:PivotTo(CFrame.new(0, 20, 0))
print("[init] jet placed at", jet:GetPivot().Position, "size", select(2, jet:GetBoundingBox()))

-- Orbit camera state
local camera = Workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Scriptable

local yaw = math.rad(35)
local pitch = math.rad(-12)
local dist = 60
local MIN_DIST, MAX_DIST = 12, 240
local PITCH_LIMIT = math.rad(85)
local YAW_SPEED = 0.006
local PITCH_SPEED = 0.005

local draggingL, draggingR = false, false

UserInputService.InputBegan:Connect(function(io: InputObject)
	if io.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingL = true
	elseif io.UserInputType == Enum.UserInputType.MouseButton2 then
		draggingR = true
	end
end)
UserInputService.InputEnded:Connect(function(io: InputObject)
	if io.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingL = false
	elseif io.UserInputType == Enum.UserInputType.MouseButton2 then
		draggingR = false
	end
end)
UserInputService.InputChanged:Connect(function(io: InputObject)
	if io.UserInputType == Enum.UserInputType.MouseMovement then
		if draggingL or draggingR then
			yaw -= io.Delta.X * YAW_SPEED
			pitch = math.clamp(pitch + io.Delta.Y * PITCH_SPEED, -PITCH_LIMIT, PITCH_LIMIT)
		end
	elseif io.UserInputType == Enum.UserInputType.MouseWheel then
		dist = math.clamp(dist - io.Position.Z * 6, MIN_DIST, MAX_DIST)
	end
end)

RunService.RenderStepped:Connect(function(_dt: number)
	local target = jet:GetPivot().Position
	local cosP, sinP = math.cos(pitch), math.sin(pitch)
	local offset = Vector3.new(math.sin(yaw) * cosP, sinP, math.cos(yaw) * cosP) * dist
	camera.CFrame = CFrame.lookAt(target + offset, target)
end)
