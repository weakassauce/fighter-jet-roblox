--!strict
-- Builds a placeholder fighter-jet Model from primitives.
-- Local forward is -Z (Roblox standard, matches CFrame.LookVector).

local JetModel = {}

local function makePart(name: string, size: Vector3, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.Metal
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

local function wedge(name: string, size: Vector3, color: Color3): WedgePart
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Size = size
	w.Color = color
	w.Material = Enum.Material.Metal
	w.Anchored = true
	w.CanCollide = false
	w.CanQuery = false
	w.CanTouch = false
	return w
end

function JetModel.build(name: string?, color: Color3?, accent: Color3?): Model
	local jet = Instance.new("Model")
	jet.Name = name or "PlayerJet"

	local bodyColor = color or Color3.fromRGB(96, 110, 130)
	local accentColor = accent or Color3.fromRGB(220, 90, 50)

	-- Fuselage (long block)
	local fuselage = makePart("Fuselage", Vector3.new(2.6, 2.4, 28), bodyColor)
	fuselage.Parent = jet

	-- Nose cone (wedge pointing forward = -Z)
	local nose = wedge("Nose", Vector3.new(2.6, 2.4, 7), bodyColor)
	nose.CFrame = CFrame.new(0, 0, -17.5) * CFrame.Angles(0, math.pi, 0)
	nose.Parent = jet

	-- Canopy (small dark wedge on top toward nose)
	local canopy = wedge("Canopy", Vector3.new(2.0, 1.2, 5), Color3.fromRGB(40, 50, 70))
	canopy.Material = Enum.Material.Glass
	canopy.Reflectance = 0.25
	canopy.CFrame = CFrame.new(0, 1.7, -6) * CFrame.Angles(0, math.pi, 0)
	canopy.Parent = jet

	-- Main wings (left + right)
	local wingL = makePart("WingL", Vector3.new(14, 0.5, 7), bodyColor)
	wingL.CFrame = CFrame.new(-7.5, -0.3, 1)
	wingL.Parent = jet
	local wingR = makePart("WingR", Vector3.new(14, 0.5, 7), bodyColor)
	wingR.CFrame = CFrame.new(7.5, -0.3, 1)
	wingR.Parent = jet

	-- Horizontal stabilizers
	local stabL = makePart("StabL", Vector3.new(6, 0.4, 3), bodyColor)
	stabL.CFrame = CFrame.new(-3.5, 0.2, 12)
	stabL.Parent = jet
	local stabR = makePart("StabR", Vector3.new(6, 0.4, 3), bodyColor)
	stabR.CFrame = CFrame.new(3.5, 0.2, 12)
	stabR.Parent = jet

	-- Vertical tail fin
	local tail = makePart("Tail", Vector3.new(0.4, 4, 4), bodyColor)
	tail.CFrame = CFrame.new(0, 2.6, 12)
	tail.Parent = jet

	-- Engine glow (neon part behind)
	local engine = makePart("EngineGlow", Vector3.new(1.6, 1.6, 0.4), Color3.fromRGB(255, 170, 60))
	engine.Material = Enum.Material.Neon
	engine.CFrame = CFrame.new(0, 0, 14.1)
	engine.Parent = jet

	-- Tail accent stripe
	local stripe = makePart("Stripe", Vector3.new(0.5, 3.5, 0.6), accentColor)
	stripe.Material = Enum.Material.SmoothPlastic
	stripe.CFrame = CFrame.new(0, 2.6, 13.7)
	stripe.Parent = jet

	jet.PrimaryPart = fuselage
	return jet
end

return JetModel
