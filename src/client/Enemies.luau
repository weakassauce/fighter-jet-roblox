--!strict
-- Enemy fighters with simple pursuit AI. Spawned, tracked, and updated client-side
-- for single-player MVP. Each enemy is a model + position/velocity/CFrame state.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Combat = require(ReplicatedStorage.Shared.Combat)
local Config = require(ReplicatedStorage.Shared.Config)
local JetModel = require(ReplicatedStorage.Shared.JetModel)

local Enemies = {}
Enemies.__index = Enemies

local function clamp(v, lo, hi)
	if v < lo then return lo end
	if v > hi then return hi end
	return v
end

local function newEnemy()
	local model = JetModel.build("EnemyJet", Color3.fromRGB(140, 40, 40), Color3.fromRGB(20, 20, 20))
	model.Parent = Workspace
	local e = {
		model = model,
		position = Vector3.zero,
		velocity = Vector3.new(0, 0, -Combat.ENEMIES.speed),
		cframe = CFrame.new(),
		hull = Combat.ENEMIES.hull,
		dead = false,
		fireCooldown = 0,
	}
	function e.takeDamage(self: any, d: number)
		if self.dead then return end
		self.hull -= d
		if self.hull <= 0 then
			self.dead = true
			if self._onDeath then self._onDeath(self.position) end
		end
	end
	return e
end

function Enemies.new(): any
	local self = setmetatable({}, Enemies)
	self.list = {}
	self.onDeath = nil :: ((Vector3) -> ())?
	for _ = 1, Combat.ENEMIES.count do
		local e = newEnemy()
		e._onDeath = function(pos: Vector3)
			if self.onDeath then self.onDeath(pos) end
		end
		table.insert(self.list, e)
	end
	return self
end

function Enemies:spawnAround(playerPos: Vector3)
	for _, e in ipairs(self.list) do
		local r = 1500 + math.random() * 2000
		local a = math.random() * math.pi * 2
		e.position = playerPos + Vector3.new(math.cos(a) * r, (math.random() - 0.5) * 400, math.sin(a) * r)
		e.velocity = (playerPos - e.position).Unit * Combat.ENEMIES.speed
		e.cframe = CFrame.lookAt(e.position, e.position + e.velocity)
		e.hull = Combat.ENEMIES.hull
		e.dead = false
		e.model.Parent = Workspace
		e.model:PivotTo(e.cframe)
	end
end

-- onShot(fromPos, direction): the enemy is firing guns
function Enemies:update(dt: number, target: any, onShot: (Vector3, Vector3) -> ())
	for _, e in ipairs(self.list) do
		if e.dead then
			e.model.Parent = nil
			continue
		end

		-- Steer toward target
		local toTarget = target.position - e.position
		local dist = toTarget.Magnitude
		local toUnit = dist > 0.001 and toTarget / dist or Vector3.new(0, 0, -1)
		local fwd = e.cframe.LookVector
		local axisVec = fwd:Cross(toUnit)
		local dotFT = clamp(fwd:Dot(toUnit), -1, 1)
		local angle = math.acos(dotFT)
		local step = math.min(angle, Combat.ENEMIES.turnRate * dt)
		if axisVec.Magnitude > 1e-6 and step > 1e-4 then
			local rot = CFrame.fromAxisAngle(axisVec.Unit, step)
			e.cframe = (rot * (e.cframe - e.cframe.Position)) + e.cframe.Position
		end

		-- Move along forward
		local newFwd = e.cframe.LookVector
		e.velocity = newFwd * Combat.ENEMIES.speed
		e.position += e.velocity * dt

		-- Floor
		if e.position.Y < 50 then
			e.position = Vector3.new(e.position.X, 50, e.position.Z)
		end

		e.cframe = CFrame.new(e.position) * (e.cframe - e.cframe.Position)
		e.model:PivotTo(e.cframe)

		-- Fire?
		e.fireCooldown -= dt
		if dist < Combat.ENEMIES.gunRange and angle < 0.15 and e.fireCooldown <= 0 then
			e.fireCooldown = 0.8 + math.random() * 0.6
			onShot(e.position, newFwd)
		end
	end
end

function Enemies:aliveList()
	local out = {}
	for _, e in ipairs(self.list) do
		if not e.dead then
			table.insert(out, e)
		end
	end
	return out
end

return Enemies
