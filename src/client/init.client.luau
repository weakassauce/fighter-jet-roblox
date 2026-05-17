--!strict
-- Client entry point: build placeholder jet, wire input + flight + camera + HUD,
-- enemies, bullets, explosions, engine flames.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local JetModel = require(Shared:WaitForChild("JetModel"))
local Combat = require(Shared:WaitForChild("Combat"))

local Client = script
local Input = require(Client:WaitForChild("Input"))
local Flight = require(Client:WaitForChild("Flight"))
local Camera = require(Client:WaitForChild("Camera"))
local Hud = require(Client:WaitForChild("Hud"))
local EngineFlames = require(Client:WaitForChild("EngineFlames"))
local Enemies = require(Client:WaitForChild("Enemies"))
local Bullets = require(Client:WaitForChild("Bullets"))
local Explosions = require(Client:WaitForChild("Explosions"))

local player = Players.LocalPlayer
if player.Character then
	player.Character:Destroy()
end

-- Build the jet
local jet = JetModel.build("PlayerJet")
jet.Parent = Workspace
jet:PivotTo(CFrame.new(0, 600, 0))

local flight = Flight.new(jet)
local input = Input.new()
local cam = Camera.new(Workspace.CurrentCamera)
local hud = Hud.new()
local flames = EngineFlames.new(jet)

-- Combat systems
local enemies = Enemies.new()
enemies:spawnAround(flight.position)
local playerBullets = Bullets.new(160, Color3.fromRGB(255, 245, 160))
local enemyBullets = Bullets.new(120, Color3.fromRGB(255, 140, 70))
local explosions = Explosions.new(12)

enemies.onDeath = function(pos: Vector3)
	explosions:spawn(pos, 35)
end

local gunCooldown = 0
local playerExploded = false

RunService.RenderStepped:Connect(function(dt: number)
	local controls = input:axes()
	for _, a in ipairs(input:drainActions()) do
		if a == "reset" then
			flight:reset()
			enemies:spawnAround(flight.position)
			playerExploded = false
		elseif a == "toggleView" then
			cam:toggleView()
		end
	end

	flight:update(dt, controls)

	-- Guns
	gunCooldown -= dt
	if controls.firingGuns and gunCooldown <= 0 and not flight.dead then
		gunCooldown = 1 / Combat.GUNS.rateOfFire
		local dir = flight:forward()
		dir = (dir + Vector3.new(
			(math.random() - 0.5) * Combat.GUNS.spread,
			(math.random() - 0.5) * Combat.GUNS.spread,
			0
		)).Unit
		local muzzle = flight.position + flight:forward() * 16
		playerBullets:spawn(muzzle, dir, flight.velocity)
	end

	-- Enemies move and shoot
	enemies:update(dt, flight, function(from: Vector3, dir: Vector3)
		enemyBullets:spawn(from + dir * 18, dir, Vector3.zero)
	end)

	-- Bullets resolve damage
	local enemyList = enemies:aliveList()
	playerBullets:update(dt, enemyList, function(t, dmg)
		t:takeDamage(dmg)
	end)
	enemyBullets:update(dt, { flight }, function(_, dmg)
		flight:takeDamage(dmg)
	end)

	-- Player death → boom
	if flight.dead and not playerExploded then
		explosions:spawn(flight.position, 55)
		playerExploded = true
		jet.Parent = nil
	end
	if not flight.dead then
		playerExploded = false
		if jet.Parent == nil then
			jet.Parent = Workspace
		end
	end

	explosions:update(dt)
	flames:update(flight)
	cam:update(dt, flight)
	hud:update(flight)
end)
