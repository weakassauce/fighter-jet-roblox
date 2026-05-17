--!strict
-- Pooled bullet system (small neon parts). Manual flight + sphere-hit check.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Combat = require(ReplicatedStorage.Shared.Combat)

local Bullets = {}
Bullets.__index = Bullets

function Bullets.new(capacity: number, color: Color3)
	local self = setmetatable({}, Bullets)
	self.capacity = capacity
	self.next = 1
	self.list = table.create(capacity)
	local folder = Instance.new("Folder")
	folder.Name = "Bullets"
	folder.Parent = Workspace
	self.folder = folder
	for _ = 1, capacity do
		local p = Instance.new("Part")
		p.Size = Vector3.new(0.6, 0.6, 2.4)
		p.Material = Enum.Material.Neon
		p.Color = color
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Transparency = 1
		p.Parent = folder
		table.insert(self.list, { mesh = p, vel = Vector3.zero, life = 0 })
	end
	return self
end

function Bullets:spawn(pos: Vector3, dir: Vector3, extraVel: Vector3?)
	local b = self.list[self.next]
	self.next = (self.next % self.capacity) + 1
	b.mesh.Transparency = 0
	b.mesh.CFrame = CFrame.lookAt(pos, pos + dir)
	b.vel = dir.Unit * Combat.GUNS.muzzleSpeed + (extraVel or Vector3.zero)
	b.life = Combat.GUNS.range / Combat.GUNS.muzzleSpeed
end

-- targets: array of { position: Vector3, dead: boolean }
-- onHit(target, damage) is invoked on any sphere intersect.
function Bullets:update(dt: number, targets: { any }, onHit: (any, number) -> ())
	for _, b in ipairs(self.list) do
		if b.life <= 0 then
			continue
		end
		b.life -= dt
		local newPos = b.mesh.Position + b.vel * dt
		b.mesh.CFrame = CFrame.lookAt(newPos, newPos + b.vel)
		for _, t in ipairs(targets) do
			if t.dead then
				continue
			end
			if (newPos - t.position).Magnitude < 12 then
				onHit(t, Combat.GUNS.damage)
				b.life = 0
				break
			end
		end
		if b.life <= 0 then
			b.mesh.Transparency = 1
			b.mesh.Position = Vector3.new(0, -5000, 0)
		end
	end
end

return Bullets
