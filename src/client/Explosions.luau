--!strict
-- Pooled explosions: flash + fireball + smoke + tumbling debris pieces.

local Workspace = game:GetService("Workspace")

local Explosions = {}
Explosions.__index = Explosions

local function makeFireball(): Part
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(1, 1, 1)
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(255, 200, 60)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	return p
end

local function makeDebris(): Part
	local sx = 0.6 + math.random() * 1.5
	local sy = 0.4 + math.random() * 1.2
	local sz = 0.8 + math.random() * 1.8
	local p = Instance.new("Part")
	p.Size = Vector3.new(sx, sy, sz)
	p.Material = Enum.Material.Metal
	p.Color = Color3.fromRGB(75, 75, 80)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	return p
end

function Explosions.new(capacity: number?)
	local self = setmetatable({}, Explosions)
	capacity = capacity or 16
	self.list = {}
	self.next = 1
	local folder = Instance.new("Folder")
	folder.Name = "Explosions"
	folder.Parent = Workspace
	self.folder = folder
	for _ = 1, capacity do
		local fire = makeFireball()
		fire.Parent = folder
		local flash = makeFireball()
		flash.Color = Color3.fromRGB(255, 255, 255)
		flash.Parent = folder
		local smoke = makeFireball()
		smoke.Material = Enum.Material.Slate
		smoke.Color = Color3.fromRGB(40, 40, 40)
		smoke.Parent = folder
		local debris = {}
		for _ = 1, 12 do
			local d = makeDebris()
			d.Parent = folder
			table.insert(debris, { mesh = d, vel = Vector3.zero, spin = Vector3.zero, life = 0, dur = 0 })
		end
		table.insert(self.list, { fire = fire, flash = flash, smoke = smoke, debris = debris, life = 0, dur = 0, scale = 1 })
	end
	return self
end

function Explosions:spawn(pos: Vector3, scale: number?)
	local s = self.list[self.next]
	self.next = (self.next % #self.list) + 1
	scale = scale or 30
	s.life = 0
	s.dur = 1.1
	s.scale = scale
	s.fire.Transparency = 0
	s.flash.Transparency = 0
	s.smoke.Transparency = 0.2
	s.fire.Position = pos
	s.flash.Position = pos
	s.smoke.Position = pos
	for _, d in ipairs(s.debris) do
		d.mesh.Transparency = 0
		d.mesh.Position = pos
		local theta = math.random() * math.pi * 2
		local phi = math.acos(1 - math.random() * 1.6)
		local sp = 35 + math.random() * 60
		d.vel = Vector3.new(
			math.sin(phi) * math.cos(theta) * sp,
			math.cos(phi) * sp + 10,
			math.sin(phi) * math.sin(theta) * sp
		)
		d.spin = Vector3.new(
			(math.random() - 0.5) * 20,
			(math.random() - 0.5) * 20,
			(math.random() - 0.5) * 20
		)
		d.life = 0
		d.dur = 2.5 + math.random() * 2.0
		d.mesh.CFrame = CFrame.new(pos)
	end
end

function Explosions:update(dt: number)
	for _, s in ipairs(self.list) do
		if s.fire.Transparency >= 1 and s.smoke.Transparency >= 1 and s.flash.Transparency >= 1 then
			-- still update debris below
		else
			s.life += dt
			local t = s.life / s.dur
			if t >= 1 then
				s.fire.Transparency = 1
				s.flash.Transparency = 1
				s.smoke.Transparency = 1
			else
				-- Flash front-loaded
				if t < 0.2 then
					local fs = s.scale * (0.6 + t * 4)
					s.flash.Size = Vector3.new(fs, fs, fs)
					s.flash.Transparency = t / 0.2
				else
					s.flash.Transparency = 1
				end
				-- Fireball expands fast, fades
				local fireGrow = 1 - (1 - t) * (1 - t)
				local fSize = math.max(0.5, s.scale * 1.3 * fireGrow)
				s.fire.Size = Vector3.new(fSize, fSize, fSize)
				s.fire.Transparency = math.max(0, t * 0.9)
				-- Color shifts toward red as it dies
				s.fire.Color = Color3.fromRGB(255, 200, 60):Lerp(Color3.fromRGB(255, 70, 30), t)
				-- Smoke expands slowly, lingers
				local smokeGrow = math.min(1, t * 1.4)
				local smSize = s.scale * 1.6 * smokeGrow
				s.smoke.Size = Vector3.new(smSize, smSize, smSize)
				s.smoke.Transparency = math.max(0.2, 0.3 + t * 0.6)
			end
		end
		-- Debris physics
		for _, d in ipairs(s.debris) do
			if d.life >= d.dur then continue end
			d.life += dt
			d.vel = Vector3.new(d.vel.X, d.vel.Y - workspace.Gravity * dt * 1.2, d.vel.Z)
			local p = d.mesh.Position + d.vel * dt
			d.mesh.CFrame = CFrame.new(p)
				* CFrame.Angles(d.spin.X * d.life, d.spin.Y * d.life, d.spin.Z * d.life)
			if d.life > d.dur * 0.7 then
				d.mesh.Transparency = (d.life - d.dur * 0.7) / (d.dur * 0.3)
			end
			if d.life >= d.dur then
				d.mesh.Transparency = 1
				d.mesh.Position = Vector3.new(0, -5000, 0)
			end
		end
	end
end

return Explosions
