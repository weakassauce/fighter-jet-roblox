--!strict
-- Engine flame ParticleEmitter on the jet's engine glow. Rate + size ride throttle.

local EngineFlames = {}
EngineFlames.__index = EngineFlames

local function makeEmitter(): ParticleEmitter
	local p = Instance.new("ParticleEmitter")
	p.Texture = "rbxasset://textures/particles/fire_main.dds"
	p.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 160)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 140, 40)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 25, 15)),
	})
	p.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 4.5),
		NumberSequenceKeypoint.new(0.5, 2.2),
		NumberSequenceKeypoint.new(1, 0.3),
	})
	p.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(0.6, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	p.Lifetime = NumberRange.new(0.25, 0.45)
	p.Rate = 0
	p.Speed = NumberRange.new(60, 90)
	p.SpreadAngle = Vector2.new(6, 6)
	p.LightEmission = 0.85
	p.LightInfluence = 0
	p.Drag = 2
	p.Rotation = NumberRange.new(0, 360)
	p.RotSpeed = NumberRange.new(-90, 90)
	p.Acceleration = Vector3.new(0, 0, 0)
	return p
end

function EngineFlames.new(jetModel: Model)
	local engine = jetModel:FindFirstChild("EngineGlow") :: Part?
	assert(engine, "EngineGlow not found")
	-- Attachment pointing along +Z (the jet's tail direction, since forward is -Z)
	local att = Instance.new("Attachment")
	att.Name = "FlameAttach"
	-- Default Attachment orientation: its +Y matches parent +Y. We want emission
	-- direction = parent +Z. So rotate so attachment Y → parent Z.
	att.CFrame = CFrame.fromAxisAngle(Vector3.new(1, 0, 0), -math.pi / 2)
	att.Parent = engine

	local outer = makeEmitter()
	outer.Parent = att
	local inner = makeEmitter()
	inner.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	inner.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2.0),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	inner.Color = ColorSequence.new(Color3.fromRGB(255, 250, 200))
	inner.LightEmission = 1.0
	inner.Speed = NumberRange.new(70, 100)
	inner.Lifetime = NumberRange.new(0.15, 0.25)
	inner.Parent = att

	local self = setmetatable({}, EngineFlames)
	self.outer = outer
	self.inner = inner
	self.engine = engine
	return self
end

function EngineFlames:update(flight: any)
	local thr = flight.throttle
	local visible = thr > 0.05 and not flight.dead
	self.outer.Rate = visible and (220 * thr) or 0
	self.inner.Rate = visible and (160 * thr) or 0
	-- Engine glow brightens with throttle
	self.engine.Color = Color3.fromRGB(255, 170, 60):Lerp(Color3.fromRGB(255, 220, 140), thr)
end

return EngineFlames
